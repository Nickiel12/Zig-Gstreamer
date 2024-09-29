const std = @import("std");
const gst = @cImport({
    @cInclude("gst.h");
});
const glib = @cImport({
    @cInclude("glib.h");
});
const gobj = @cImport({
    @cInclude("glib-object.h");
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

    // const bin: ?*gst.GstBin = gobj.G_TYPE_CHECK_INSTANCE_CAST(pipeline, gst.GST_TYPE_BIN, gst.GstBin);
    const bin: *gst.GstBin = @ptrCast(pipeline);
    // gst.g_object_get(gst.G_OBJECT(pipeline), "bin", &bin, null);

    gst.gst_bin_add_many(bin, source, sink, null);
    if (gst.gst_element_link(source, sink) != true) {
        gst.gst_object_unref(pipeline);
        std.debug.panic("Elements could not be linked", .{});
    }

    gst.g_object_set(source, "pattern", 0, null);

    const ret = gst.gst_element_set_state(pipeline, gst.GST_STATE_PLAYING);
    if (ret == gst.GST_STATE_CHANGE_FAILURE) {
        gst.gst_object_unref(pipeline);
        std.debug.panic("Could not start pipeline", .{});
    }

    const bus: *gst.GstBus = gst.gst_element_get_bus(pipeline);
    const msg: *gst.GstMessage = gst.gst_bus_timed_pop_filtered(
        bus,
        gst.GST_CLOCK_TIME_NONE,
        gst.GST_MESSAGE_ERROR | gst.GST_MESSAGE_EOS,
    );

    if (gst.GST_MESSAGE_TYPE(msg) == gst.GST_MESSAGE_ERROR) {
        var err: ?*gst.GError = null;
        var debug_info: ?*gst.gchar = null;

        switch (gst.GST_MESSAGE_TYPE(msg)) {
            gst.GST_MESSAGE_ERROR => {
                gst.gst_messsage_parse_error(msg, &err, &debug_info);
                std.debug.print("Error received from element {s}: {s}", .{ gst.GST_OBJECT_NAME(msg.src), err.message });
                std.debug.print("Debugging information: {s}", .{debug_info orelse "none"});
                gst.g_clear_error(&err);
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
