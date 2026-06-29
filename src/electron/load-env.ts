import { config } from "dotenv";
import { app } from "electron";
import path from "path";

config({
  path: app.isPackaged
    ? path.join(process.resourcesPath, ".env")
    : undefined,
});
