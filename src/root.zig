const std = @import("std");

const GGATokenPosition = enum(u32) { gga, time, lat, ns, lon, ew, quality, sats, hdop, alt, alt_unit, geoidal, geoidal_unit, corr_age, corr_sta, checksum };
const RMCTokenPosition = enum(u32) { rmc, time, status, lat, ns, long, ew, speed, course, date, magvar, magvardir, mode, navstatus, checksum };
pub const GPSSentence = enum(u32) { gga, rmc, other, invalid };

const GpsError = error{
    NoValidSentence,
    ParseErrorTime,
    ParseErrorLat,
    ParseErrorLon,
    ParseErrorQuality,
    ParseErrorAlt,
    ParseErrorSats,
    ParseErrorSpeed,
    ParseErrorCourse,
    ParseErrorDate,
};

const GpsData = struct {
    sentence: GPSSentence = GPSSentence.invalid,
    latitude: f32 = 0.0,
    ns: []const u8 = "N",
    longitude: f32 = 0.0,
    ew: []const u8 = "W",
    quality: u32 = 0,
    altitude: f32 = 0.0,
    altitude_unit: []const u8 = "",
    hour: u32 = 0,
    minute: u32 = 0,
    second: u32 = 0,
    sats: u32 = 0,
    day: u32 = 0,
    month: u32 = 0,
    year: u32 = 0,
    speed: f32 = 0,
    course: f32 = 0,
};

pub fn parseSentence(data: []const u8) !GpsData {
    var parsed_data: GpsData = .{};
    var tokens = std.mem.splitScalar(u8, data, ',');
    var token_counter: u32 = 0;
    while (tokens.next()) |token| {
        if (token_counter == 0) {
            if (std.mem.eql(u8, token, "$GPGGA")) {
                parsed_data.sentence = GPSSentence.gga;
            } else if (std.mem.eql(u8, token, "$GPRMC")) {
                parsed_data.sentence = GPSSentence.rmc;
            } else {
                return error.NoValidSentence;
            }
        }
        // fields can be null
        if (token.len == 0) {
            token_counter += 1;
            continue;
        }
        if (token_counter == 1) {
            // time for GGA and RMC
            parsed_data.hour = std.fmt.parseInt(u32, token[0..2], 10) catch {
                return GpsError.ParseErrorTime;
            };
            parsed_data.minute = std.fmt.parseInt(u32, token[2..4], 10) catch {
                return GpsError.ParseErrorTime;
            };
            parsed_data.second = std.fmt.parseInt(u32, token[4..6], 10) catch {
                return GpsError.ParseErrorTime;
            };
        }
        // now fields are different for different sentences
        switch (parsed_data.sentence) {
            GPSSentence.gga => {
                switch (token_counter) {
                    // latitude
                    @intFromEnum(GGATokenPosition.lat) => {
                        parsed_data.latitude = std.fmt.parseFloat(f32, token) catch {
                            return GpsError.ParseErrorLat;
                        };
                    },
                    @intFromEnum(GGATokenPosition.ns) => {
                        parsed_data.ns = token;
                    },
                    // longitude
                    @intFromEnum(GGATokenPosition.lon) => {
                        parsed_data.longitude = std.fmt.parseFloat(f32, token) catch {
                            return GpsError.ParseErrorLon;
                        };
                    },
                    @intFromEnum(GGATokenPosition.ew) => {
                        parsed_data.ew = token;
                    },
                    // quality
                    @intFromEnum(GGATokenPosition.quality) => {
                        parsed_data.quality = std.fmt.parseInt(u32, token, 10) catch {
                            return GpsError.ParseErrorQuality;
                        };
                    },
                    // altitude
                    @intFromEnum(GGATokenPosition.alt) => {
                        parsed_data.altitude = std.fmt.parseFloat(f32, token) catch {
                            return GpsError.ParseErrorAlt;
                        };
                    },
                    @intFromEnum(GGATokenPosition.alt_unit) => {
                        parsed_data.altitude_unit = token;
                    },
                    // satellites
                    @intFromEnum(GGATokenPosition.sats) => {
                        parsed_data.sats = std.fmt.parseInt(u32, token, 10) catch {
                            return GpsError.ParseErrorSats;
                        };
                    },
                    else => {},
                }
            },
            GPSSentence.rmc => {
                switch (token_counter) {
                    // speed
                    @intFromEnum(RMCTokenPosition.speed) => {
                        parsed_data.speed = std.fmt.parseFloat(f32, token) catch {
                            return GpsError.ParseErrorSpeed;
                        };
                    },
                    // course
                    @intFromEnum(RMCTokenPosition.course) => {
                        parsed_data.course = std.fmt.parseFloat(f32, token) catch {
                            return GpsError.ParseErrorCourse;
                        };
                    },
                    // date
                    @intFromEnum(RMCTokenPosition.date) => {
                        parsed_data.day = std.fmt.parseInt(u32, token[0..2], 10) catch {
                            return GpsError.ParseErrorDate;
                        };
                        parsed_data.month = std.fmt.parseInt(u32, token[2..4], 10) catch {
                            return GpsError.ParseErrorDate;
                        };
                        parsed_data.year = std.fmt.parseInt(u32, token[4..6], 10) catch {
                            return GpsError.ParseErrorDate;
                        };
                    },
                    else => {},
                }
            },
            else => {
                return GpsError.NoValidSentence;
            },
        }
        token_counter += 1;
    }
    return parsed_data;
}

pub fn nmeaToDec(coord: f32, dir: []const u8) f32 {
    const degrees = @trunc(coord / 100);
    const fraction = (coord - (degrees * 100.0)) / 60.0;

    var dec = degrees + fraction;
    if (std.mem.eql(u8, dir, "S") or std.mem.eql(u8, dir, "W")) {
        dec *= -1;
    }

    return dec;
}
