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

#ifndef SEEK_PREVIEW_HPP
#define SEEK_PREVIEW_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QObject>
#include <QImage>
#include <QMutex>
#include <QVector>
#include <QQuickImageProvider>

#include <memory>

#include "qt.hpp"

class PlayerController;
typedef struct vlc_preparser_t vlc_preparser_t;
typedef struct vlc_preparser_req vlc_preparser_req;

/**
 * Builds a strip of preview frames for the current local video in the
 * background, the way web players do, so hovering the seek bar can show
 * a frame without decoding on demand.
 *
 * QML reads frames through the "seekpreview" image provider, using the
 * URL returned by source().
 */
class SeekPreview : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool available READ isAvailable NOTIFY revisionChanged FINAL)
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged FINAL)

public:
    static constexpr int maxFrames = 100;
    static constexpr int frameWidth = 256;

    struct Store
    {
        QMutex lock;
        unsigned generation = 0;
        QVector<QImage> frames;
    };

    SeekPreview(qt_intf_t *intf, PlayerController *player, QObject *parent = nullptr);
    ~SeekPreview() override;

    QQuickImageProvider *createImageProvider() const;

    bool isAvailable() const { return m_ready > 0; }
    int revision() const { return m_revision; }

    /// image URL for the frame nearest to @p position (0..1), empty if none yet
    Q_INVOKABLE QString source(double position) const;

signals:
    void revisionChanged();

private:
    struct Request;
    static void onThumbnailEnded(vlc_preparser_req *, int status,
                                 picture_t *, void *data);

    void update();
    void reset();
    void start(input_item_t *item, int count);
    void onFrame(unsigned generation, int index, const QImage &image);
    QImage convert(picture_t *picture);

    qt_intf_t *m_intf;
    PlayerController *m_player;
    vlc_preparser_t *m_preparser = nullptr;
    image_handler_t *m_converter = nullptr; // only used on the thumbnailer thread
    input_item_t *m_item = nullptr;
    std::shared_ptr<Store> m_store;
    int m_count = 0;
    int m_ready = 0;
    int m_revision = 0;
};

#endif // SEEK_PREVIEW_HPP
