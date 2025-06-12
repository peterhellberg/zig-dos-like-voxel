// Zig port of Mattias Gustavssons port of
// voxel code by Sebastian Macke
//
// - https://github.com/mattiasgustavsson/dos-like/blob/main/source/voxel.c
// - https://github.com/s-macke/VoxelSpace
//
// See end of file for original license
//                     / Peter Hellberg

const std = @import("std");
const mem = std.mem;

const dos = @cImport({
    @cInclude("dos.h");
});

const Cam = struct {
    x: f32 = mem.zeroes(f32),
    y: f32 = mem.zeroes(f32),
    height: f32 = mem.zeroes(f32),
    angle: f32 = mem.zeroes(f32),
    horizon: f32 = mem.zeroes(f32),
    distance: f32 = mem.zeroes(f32),
};

pub export fn dosmain() c_int {
    dos.setvideomode(dos.videomode_320x200);

    var palette: [768]u8 = undefined;
    var mapwidth: c_int = undefined;
    var mapheight: c_int = undefined;
    var palcount: c_int = undefined;

    const mapcol: [*c]u8 = dos.loadgif(
        "files/C1W.gif",
        &mapwidth,
        &mapheight,
        &palcount,
        &palette[0],
    );

    const mapalt: [*c]u8 = dos.loadgif(
        "files/D1.gif",
        &mapwidth,
        &mapheight,
        null,
        null,
    );

    {
        var i: u8 = 0;

        while (i < palcount) : (i += 1) {
            dos.setpal(
                i,
                palette[3 * i + 0],
                palette[3 * i + 1],
                palette[3 * i + 2],
            );
        }
    }

    dos.setpal(0, 36, 36, 56);

    var cam: Cam = .{
        .x = 500,
        .y = 400,
        .height = 128,
        .angle = 0,
        .horizon = 90,
        .distance = 800,
    };

    dos.setdoublebuffer(1);

    var screen: [*c]u8 = dos.screenbuffer();

    while (!(dos.shuttingdown() != 0)) {
        dos.waitvbl();
        dos.clearscreen();

        if (dos.keystate(dos.KEY_LEFT) != 0) {
            cam.angle += 0.019999999552965164;
        }

        if (dos.keystate(dos.KEY_RIGHT) != 0) {
            cam.angle -= 0.019999999552965164;
        }

        if (dos.keystate(dos.KEY_UP) != 0) {
            cam.x -= std.math.sin(cam.angle) * 1.100000023841858;
            cam.y -= std.math.cos(cam.angle) * 1.100000023841858;
        }

        if (dos.keystate(dos.KEY_DOWN) != 0) {
            cam.x += std.math.sin(cam.angle) * 0.75;
            cam.y += std.math.cos(cam.angle) * 0.75;
        }

        if (dos.keystate(dos.KEY_R) != 0) {
            cam.height += 0.5;
        }

        if (dos.keystate(dos.KEY_F) != 0) {
            cam.height -= 0.5;
        }

        if (dos.keystate(dos.KEY_Q) != 0) {
            cam.horizon += 1.5;
        }

        if (dos.keystate(dos.KEY_W) != 0) {
            cam.horizon -= 1.5;
        }

        const mapwidthperiod: c_int = mapwidth - 1;
        const mapheightperiod: c_int = mapheight - 1;
        const mapshift: c_int = 10;

        const cameraoffs: c_int = ((@as(
            c_int,
            @intFromFloat(cam.y),
        ) & mapwidthperiod) << @intCast(mapshift)) + (@as(
            c_int,
            @intFromFloat(cam.x),
        ) & mapheightperiod);

        const h: f32 = (@as(f32, @floatFromInt(@as(c_int, @bitCast(
            @as(c_uint, (blk: {
                const tmp = cameraoffs;

                if (tmp >= 0)
                    break :blk mapalt + @as(usize, @intCast(tmp))
                else
                    break :blk mapalt - ~@as(usize, @bitCast(@as(
                        isize,
                        @intCast(tmp),
                    ) +% -1));
            }).*),
        )))) + 10.0);

        if (h > cam.height) {
            cam.height = @as(f32, @floatFromInt(
                @as(c_int, @bitCast(
                    @as(c_uint, (blk: {
                        const tmp = cameraoffs;

                        if (tmp >= 0)
                            break :blk mapalt + @as(usize, @intCast(tmp))
                        else
                            break :blk mapalt - ~@as(usize, @bitCast(@as(
                                isize,
                                @intCast(tmp),
                            ) +% -1));
                    }).*),
                )),
            )) + 10.0;
        }

        const width: c_int = 320;
        const height: c_int = 200;

        const sinang: f32 = std.math.sin(cam.angle);
        const cosang: f32 = std.math.cos(cam.angle);

        var hiddeny: [320]c_int = undefined;
        {
            var i: c_int = 0;

            while (i < width) : (i += 1) {
                hiddeny[@as(c_uint, @intCast(i))] = height;
            }
        }

        var deltaz: f32 = 1.0;
        {
            var z: f32 = 1.0;

            while (z < cam.distance) : (z += deltaz) {
                var plx: f32 = (-cosang * z) - (sinang * z);
                var ply: f32 = (sinang * z) - (cosang * z);

                const prx: f32 = (cosang * z) - (sinang * z);
                const pry: f32 = (-sinang * z) - (cosang * z);
                const dx: f32 = (prx - plx) / @as(f32, @floatFromInt(width));
                const dy: f32 = (pry - ply) / @as(f32, @floatFromInt(width));

                plx += cam.x;
                ply += cam.y;

                const invz: f32 = (1.0 / z) * 100.0;
                {
                    var i: c_int = 0;

                    while (i < width) : (i += 1) {
                        const mapoffset: c_int = ((@as(
                            c_int,
                            @intFromFloat(ply),
                        ) & mapwidthperiod) << @intCast(mapshift)) +
                            (@as(
                                c_int,
                                @intFromFloat(plx),
                            ) & mapheightperiod);

                        var heightonscreen: c_int = @as(
                            c_int,
                            @intFromFloat(((cam.height - @as(
                                f32,
                                @floatFromInt(@as(c_int, @bitCast(@as(c_uint, (blk: {
                                    const tmp = mapoffset;

                                    if (tmp >= 0)
                                        break :blk mapalt + @as(usize, @intCast(tmp))
                                    else
                                        break :blk mapalt - ~@as(usize, @bitCast(@as(
                                            isize,
                                            @intCast(tmp),
                                        ) +% -1));
                                }).*)))),
                            )) * invz) + cam.horizon),
                        );

                        if (heightonscreen < 0) {
                            heightonscreen = 0;
                        }

                        const col: c_int = @as(c_int, @bitCast(@as(c_uint, (blk: {
                            const tmp = mapoffset;

                            if (tmp >= 0)
                                break :blk mapcol + @as(usize, @intCast(tmp))
                            else
                                break :blk mapcol - ~@as(usize, @bitCast(@as(
                                    isize,
                                    @intCast(tmp),
                                ) +% -1));
                        }).*)));

                        var y: c_int = heightonscreen;

                        while (y < hiddeny[@as(c_uint, @intCast(i))]) : (y += 1) {
                            (blk: {
                                const tmp = i + (y * 320);

                                if (tmp >= 0)
                                    break :blk screen + @as(
                                        usize,
                                        @intCast(tmp),
                                    )
                                else
                                    break :blk screen - ~@as(
                                        usize,
                                        @bitCast(@as(isize, @intCast(tmp)) +% -1),
                                    );
                            }).* = @as(
                                u8,
                                @bitCast(@as(i8, @truncate(col))),
                            );
                        }

                        const idx: c_uint = @intCast(i);

                        if (heightonscreen < hiddeny[idx]) {
                            hiddeny[idx] = heightonscreen;
                        }

                        plx += dx;
                        ply += dy;
                    }
                }

                deltaz += 0.004999999888241291;
            }
        }

        dos.setcolor(255);
        dos.outtextxy(10, 10, "UP/DOWN/LEFT/RIGHT - move/turn");
        dos.outtextxy(10, 18, "R/F - change altitude");
        dos.outtextxy(10, 26, "Q/W - change pitch");

        screen = dos.swapbuffers();

        if (dos.keystate(dos.KEY_ESCAPE) != 0) break;
    }

    return 0;
}

pub extern fn main() u8;

// License of the original version by Sebastian Macke

// MIT License
//
// Copyright (c) 2017 Sebastian Macke
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
