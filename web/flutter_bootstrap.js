{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorker: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function (engineInitializer) {
    var loader = document.getElementById('loading');
    if (loader != null) {
      console.log('remove')
      loader.remove();
    }
    engineInitializer.initializeEngine().then(function (appRunner) {
      appRunner.runApp();
    });
  }
});
