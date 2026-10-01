{{flutter_js}}
{{flutter_build_config}}

// Keep the local development portal usable on restricted/offline networks.
// The matching CanvasKit files are bundled under web/canvaskit.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});
