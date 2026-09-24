{
  grpcServers: [{
    listenAddresses: [':8980'],
    authenticationPolicy: { allow: {} },
  }],
  maximumMessageSizeBytes: 16 * 1024 * 1024,
  global: {
    diagnosticsHttpServer: {
      httpServers: [{
        listenAddresses: [':9980'],
        authenticationPolicy: { allow: {} },
      }],
    },
    enablePrometheus: true,
    enablePprof: true,
  },
  contentAddressableStorage: {
    backend: {
      'local': {
        keyLocationMapOnBlockDevice: {
          file: {
            path: '/storage-cas/key_location_map',
            sizeBytes: 16 * 1024 * 1024,
          },
        },
        keyLocationMapMaximumGetAttempts: 16,
        keyLocationMapMaximumPutAttempts: 64,
        oldBlocks: 8,
        currentBlocks: 24,
        newBlocks: 3,
        blocksOnBlockDevice: {
          source: {
            file: {
              path: '/storage-cas/blocks',
              sizeBytes: 10 * 1024 * 1024 * 1024,
            },
          },
          spareBlocks: 3,
        },
        persistent: {
          stateDirectoryPath: '/storage-cas/persistent_state',
          minimumEpochInterval: '300s',
        },
      },
    },
    getAuthorizer: { allow: {} },
    putAuthorizer: { allow: {} },
    findMissingAuthorizer: { allow: {} },
  },
  actionCache: {
    backend: {
      completenessChecking: {
        backend: {
          'local': {
            keyLocationMapOnBlockDevice: {
              file: {
                path: '/storage-ac/key_location_map',
                sizeBytes: 1024 * 1024,
              },
            },
            keyLocationMapMaximumGetAttempts: 16,
            keyLocationMapMaximumPutAttempts: 64,
            oldBlocks: 8,
            currentBlocks: 24,
            newBlocks: 1,
            blocksOnBlockDevice: {
              source: {
                file: {
                  path: '/storage-ac/blocks',
                  sizeBytes: 100 * 1024 * 1024,
                },
              },
              spareBlocks: 3,
            },
            persistent: {
              stateDirectoryPath: '/storage-ac/persistent_state',
              minimumEpochInterval: '300s',
            },
          },
        },
        maximumTotalTreeSizeBytes: 16 * 1024 * 1024,
      },
    },
    getAuthorizer: { allow: {} },
    putAuthorizer: { allow: {} },
  },
  executeAuthorizer: { allow: {} },
}
