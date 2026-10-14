/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#include "seek_preview.hpp"

#include "player/player_controller.hpp"

#include <vlc_image.h>
#include <vlc_input_item.h>
#include <vlc_picture.h>
#include <vlc_player.h>
#include <vlc_preparser.h>

#include <cstring>

namespace {

class SeekPreviewImageProvider : public QQuickImageProvider
{
public:
    explicit SeekPreviewImageProvider(std::shared_ptr<SeekPreview::Store> store)
        : QQuickImageProvider(QQuickImageProvider::Image)
        , m_store(std::move(store))
    {}

    // id is "<generation>/<index>"
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        const QStringList parts = id.split('/');
        if (parts.size() != 2)
            return {};

        QImage image;
        {
            QMutexLocker locker(&m_store->lock);
            const int index = parts[1].toInt();
            if (parts[0].toUInt() != m_store->generation
             || index < 0 || index >= m_store->frames.size())
                return {};
            image = m_store->frames[index];
        }

        if (size)
            *size = image.size();
        if (requestedSize.isValid() && !image.isNull())
            image = image.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        return image;
    }

private:
    std::shared_ptr<SeekPreview::Store> m_store;
};

}

struct SeekPreview::Request
{
    SeekPreview *self;
    unsigned generation;
    int index;
};

SeekPreview::SeekPreview(qt_intf_t *intf, PlayerController *player, QObject *parent)
    : QObject(parent)
    , m_intf(intf)
    , m_player(player)
    , m_store(std::make_shared<Store>())
{
    connect(player, &PlayerController::inputChanged, this, &SeekPreview::update);
    connect(player, &PlayerController::lengthChanged, this, &SeekPreview::update);
    connect(player, &PlayerController::hasVideoOutputChanged, this, &SeekPreview::update);
}

SeekPreview::~SeekPreview()
{
    if (m_preparser)
    {
        vlc_preparser_Cancel(m_preparser, nullptr);
        vlc_preparser_Delete(m_preparser);
    }
    // the thumbnailer thread is gone, the converter is ours again
    if (m_converter)
        image_HandlerDelete(m_converter);
    if (m_item)
        input_item_Release(m_item);
}

QQuickImageProvider *SeekPreview::createImageProvider() const
{
    return new SeekPreviewImageProvider(m_store);
}

QString SeekPreview::source(double position) const
{
    if (m_ready == 0 || m_count == 0)
        return {};

    const int wanted = std::clamp(static_cast<int>(position * m_count), 0, m_count - 1);

    QMutexLocker locker(&m_store->lock);
    // while the strip is still filling in, fall back to the closest frame
    for (int distance = 0; distance < m_count; ++distance)
    {
        for (const int index : { wanted - distance, wanted + distance })
        {
            if (index >= 0 && index < m_store->frames.size() && !m_store->frames[index].isNull())
                return QStringLiteral("image://seekpreview/%1/%2").arg(m_store->generation).arg(index);
        }
    }
    return {};
}

void SeekPreview::update()
{
    input_item_t *item = nullptr;
    vlc_tick_t length = 0;
    {
        vlc_player_t *player = m_player->getPlayer();
        vlc_player_locker lock{ player };
        item = vlc_player_GetCurrentMedia(player);
        if (item)
        {
            input_item_Hold(item);
            length = vlc_player_GetLength(player);
        }
    }

    if (item == m_item)
    {
        if (item)
            input_item_Release(item);
        if (m_count > 0 || !m_item)
            return; // already generated (or generating) for this item
    }
    else
    {
        reset();
        m_item = item;
    }

    if (!m_item || length <= 0 || !m_player->hasVideoOutput())
        return;

    // every other open would hit the network or a device: local files only
    if (!m_item->psz_uri || strncmp(m_item->psz_uri, "file://", 7) != 0)
        return;

    const int count = std::clamp(static_cast<int>(SEC_FROM_VLC_TICK(length) / 2), 1, maxFrames);
    start(m_item, count);
}

void SeekPreview::reset()
{
    if (m_preparser)
        vlc_preparser_Cancel(m_preparser, nullptr);

    {
        QMutexLocker locker(&m_store->lock);
        ++m_store->generation;
        m_store->frames.clear();
    }

    if (m_item)
    {
        input_item_Release(m_item);
        m_item = nullptr;
    }

    m_count = 0;
    m_ready = 0;
    ++m_revision;
    emit revisionChanged();
}

void SeekPreview::start(input_item_t *item, int count)
{
    if (!m_preparser)
    {
        vlc_preparser_cfg cfg{};
        cfg.types = VLC_PREPARSER_TYPE_THUMBNAIL;
        cfg.max_thumbnailer_threads = 1;
        cfg.timeout = VLC_TICK_FROM_SEC(5);
        cfg.external_process = false;
        m_preparser = vlc_preparser_New(VLC_OBJECT(m_intf), &cfg);
        if (!m_preparser)
            return;
    }

    unsigned generation;
    {
        QMutexLocker locker(&m_store->lock);
        generation = m_store->generation;
        m_store->frames = QVector<QImage>(count);
    }
    m_count = count;

    // coarse to fine, so the whole bar is roughly covered early on
    QVector<int> order;
    order.reserve(count);
    QVector<bool> queued(count, false);
    int stride = 1;
    while (stride * 2 < count)
        stride *= 2;
    for (; stride >= 1; stride /= 2)
    {
        for (int index = 0; index < count; index += stride)
        {
            if (!queued[index])
            {
                queued[index] = true;
                order.append(index);
            }
        }
    }

    static const vlc_thumbnailer_cbs cbs = { &SeekPreview::onThumbnailEnded };

    for (const int index : order)
    {
        vlc_thumbnailer_arg arg{};
        arg.seek.type = vlc_thumbnailer_arg::seek::VLC_THUMBNAILER_SEEK_POS;
        arg.seek.pos = (index + 0.5) / count;
        arg.seek.speed = vlc_thumbnailer_arg::seek::VLC_THUMBNAILER_SEEK_FAST;
        arg.hw_dec = false;

        auto request = new Request{ this, generation, index };
        vlc_preparser_req *req = vlc_preparser_req_NewThumbnail(m_preparser, item, &arg, &cbs, request);
        if (!req)
        {
            delete request;
            break;
        }
        // on success the running task owns the request and calls us back once
        if (vlc_preparser_Submit(m_preparser, req) != VLC_SUCCESS)
            delete request;
        vlc_preparser_req_Release(req);
    }
}

void SeekPreview::onThumbnailEnded(vlc_preparser_req *, int status, picture_t *picture, void *data)
{
    auto request = static_cast<Request *>(data);
    if (status == VLC_SUCCESS && picture)
    {
        SeekPreview *self = request->self;
        const QImage image = self->convert(picture);
        if (!image.isNull())
        {
            const unsigned generation = request->generation;
            const int index = request->index;
            QMetaObject::invokeMethod(self, [self, generation, index, image] {
                self->onFrame(generation, index, image);
            }, Qt::QueuedConnection);
        }
    }
    delete request;
}

QImage SeekPreview::convert(picture_t *picture)
{
    if (!m_converter)
    {
        m_converter = image_HandlerCreate(m_intf);
        if (!m_converter)
            return {};
    }

    const video_format_t &in = picture->format;
    if (in.i_visible_width == 0 || in.i_visible_height == 0)
        return {};

    // square pixels at a fixed width, keeping the display aspect ratio
    const unsigned sarNum = in.i_sar_num ? in.i_sar_num : 1;
    const unsigned sarDen = in.i_sar_den ? in.i_sar_den : 1;
    const unsigned height = std::max<uint64_t>(1,
        uint64_t{frameWidth} * in.i_visible_height * sarDen / (uint64_t{in.i_visible_width} * sarNum)) & ~1u;

    video_format_t out;
    video_format_Init(&out, VLC_CODEC_RGBA);
    out.i_width = out.i_visible_width = frameWidth;
    out.i_height = out.i_visible_height = std::max(2u, height);
    out.i_sar_num = out.i_sar_den = 1;

    picture_t *rgba = image_Convert(m_converter, picture, &in, &out);
    video_format_Clean(&out);
    if (!rgba)
        return {};

    const plane_t &plane = rgba->p[0];
    const QImage image = QImage(plane.p_pixels, rgba->format.i_visible_width,
                                rgba->format.i_visible_height, plane.i_pitch,
                                QImage::Format_RGBA8888).copy();
    picture_Release(rgba);
    return image;
}

void SeekPreview::onFrame(unsigned generation, int index, const QImage &image)
{
    {
        QMutexLocker locker(&m_store->lock);
        if (generation != m_store->generation || index >= m_store->frames.size())
            return;
        m_store->frames[index] = image;
    }
    ++m_ready;
    ++m_revision;
    emit revisionChanged();
}
