const std = @import("std");
const gst = @cImport({ // glib-object for g_object_* functions
    @cInclude("glib-object.h");
    @cInclude("gst.h");
    @cInclude("glib.h"); // and glib for other g_* functions
});

pub fn main() void {
    // This allows me to utilize the same command line args and gstreamer
    gst.gst_init(@ptrCast(&std.os.argv.len), @ptrCast(&std.os.argv.ptr));

    const source: ?*gst.GstElement = gst.gst_element_factory_make("videotestsrc", "source");
    const sink: ?*gst.GstElement = gst.gst_element_factory_make("autovideosink", "sink");

    const pipeline: ?*gst.GstElement = gst.gst_pipeline_new("test-pipeline");

    if (source == null or sink == null or pipeline == null) {
        std.debug.panic("Not all elements could be created!", .{});
    }

    // When you look into the GST_BIN macro that zig can't compile,
    // it really is just this pointer cast with extra steps of verification
    const bin: *gst.GstBin = @ptrCast(pipeline);


    // Gstreamer gives a critical warning when using gst.gst_bin_add_many, but doesn't
    // when calling each individually
    _ = gst.gst_bin_add(bin, source);
    _ = gst.gst_bin_add(bin, sink);

    // the failure return code is -1 I believe
    if (gst.gst_element_link(source, sink) < 0) {
        gst.gst_object_unref(pipeline);
        std.debug.panic("Elements could not be linked\n", .{});
    }

    // g_int is just i32. You can 
    gst.g_object_set(source, "pattern", @as(i16, 0));

    const ret = gst.gst_element_set_state(pipeline, gst.GST_STATE_PLAYING);
    if (ret == gst.GST_STATE_CHANGE_FAILURE) {
        gst.gst_object_unref(pipeline);
        std.debug.panic("Could not start pipeline", .{});
    }

    const bus: *gst.GstBus = gst.gst_element_get_bus(pipeline);
    const msg: *gst.GstMessage = gst.gst_bus_timed_pop_filtered( // This call holds until there is a valid message
        bus,
        gst.GST_CLOCK_TIME_NONE,
        gst.GST_MESSAGE_ERROR | gst.GST_MESSAGE_EOS,
    );

    if (gst.GST_MESSAGE_TYPE(msg) == gst.GST_MESSAGE_ERROR) {
        const err: [*c][*c]gst.GError = null;
        var debug_info: ?*gst.gchar = null;

        switch (gst.GST_MESSAGE_TYPE(msg)) {
            gst.GST_MESSAGE_ERROR => {
                gst.gst_message_parse_error(msg, err, &debug_info);
                std.debug.print("Error received from element {s}: {s}", .{ gst.GST_OBJECT_NAME(msg.src), err.*.*.message });
                if (debug_info != null) { // I couldn't figure out how to do a orelse statement for this unwrap. 
                    std.debug.print("Debugging information: {s}", .{debug_info.?});
                }
                gst.g_clear_error(err);
                gst.g_free(debug_info);
            },
            else => {},
        }
        gst.gst_message_unref(msg);
    }

    gst.gst_object_unref(bus);
    _ = gst.gst_element_set_state(pipeline, gst.GST_STATE_NULL);
    gst.gst_object_unref(pipeline);
}
