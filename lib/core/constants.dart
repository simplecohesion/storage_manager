String getFileNameFromStoragePath(String storagePath) =>
    storagePath.substring(storagePath.lastIndexOf("/") + 1);
