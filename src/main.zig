const std = @import("std");
const nmea = @import("nmea");

const sentences: [6][]const u8 = .{
    "$GPGGA,,,,,,,,,,M,,M,,*56",
    "$GPGGA,181908.00,4332.944,N,539.783,W,4,13,1.00,495.144,M,29.200,M,0.10,0000*40",
    "$GPGGA,235947.000,0000.0000,N,00000.0000,E,0,00,0.0,0.0,M,,,,0000*00",
    "$GPRMC,235947.000,V,0000.0000,N,00000.0000,E,,,041299,,*1D",
    "$GPRMC,092204.999,A,4250.5589,S,14718.5084,E,0.00,89.68,211200,,*25",
    "50.5589,S,14718.5084,E,0.00,89.68,211200,,*25",
};

pub fn main() !void {
    for (sentences) |sentence| {
        if (nmea.parseSentence(sentence)) |parsed| {
            if (parsed.sentence == nmea.GPSSentence.gga) {
                std.debug.print("{:02}:{:02}:{:02} Coords {:.5}, {:.5}, altitude: {:.1}{s}, sats {d}\n", .{
                    parsed.hour,
                    parsed.minute,
                    parsed.second,
                    nmea.nmeaToDec(parsed.latitude, parsed.ns),
                    nmea.nmeaToDec(parsed.longitude, parsed.ew),
                    parsed.altitude,
                    parsed.altitude_unit,
                    parsed.sats,
                });
            } else if (parsed.sentence == nmea.GPSSentence.rmc) {
                std.debug.print("{:02}:{:02}:{:02} Date {:02}/{:02}/{:02}, speed {d}kn, course: {d}º\n", .{
                    parsed.hour,
                    parsed.minute,
                    parsed.second,
                    parsed.day,
                    parsed.month,
                    parsed.year,
                    parsed.speed,
                    parsed.course,
                });
            }
        } else |err| {
            std.debug.print("Error parsing sentence: {s}\n", .{@errorName(err)});
        }
    }
}
