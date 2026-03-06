import fs from "fs";
import path from "path";
import AdmZip from "adm-zip";
import { createRequire } from "module";
import fsp from "fs/promises";
import { getOctokit, context } from "@actions/github";

const target = process.argv.slice(2)[0];
const alpha = process.argv.slice(2)[1];
const ARCH_MAP = {
  "x86_64-pc-windows-msvc": "x64",
  "aarch64-pc-windows-msvc": "arm64",
};

const PROCESS_MAP = {
  x64: "x64",
  arm64: "arm64",
};
const arch = target ? ARCH_MAP[target] : PROCESS_MAP[process.arch];

function resolveWindowsExecutable(releaseDir) {
  const candidates = ["Clash Verge.exe", "clash-verge.exe"];

  for (const fileName of candidates) {
    const filePath = path.join(releaseDir, fileName);
    if (fs.existsSync(filePath)) {
      return filePath;
    }
  }

  throw new Error("could not found the app executable");
}
/// Script for ci
/// 打包绿色版/便携版 (only Windows)
async function resolvePortable() {
  if (process.platform !== "win32") return;

  const releaseDir = target
    ? `./src-tauri/target/${target}/release`
    : `./src-tauri/target/release`;
  const configDir = path.join(releaseDir, ".config");

  if (!fs.existsSync(releaseDir)) {
    throw new Error("could not found the release dir");
  }

  await fsp.mkdir(configDir, { recursive: true });
  if (!fs.existsSync(path.join(configDir, "PORTABLE"))) {
    await fsp.writeFile(path.join(configDir, "PORTABLE"), "");
  }
  const zip = new AdmZip();

  zip.addLocalFile(resolveWindowsExecutable(releaseDir));
  zip.addLocalFile(path.join(releaseDir, "verge-mihomo.exe"));
  zip.addLocalFile(path.join(releaseDir, "verge-mihomo-alpha.exe"));
  zip.addLocalFolder(path.join(releaseDir, "resources"), "resources");
  zip.addLocalFolder(configDir, ".config");

  const require = createRequire(import.meta.url);
  const packageJson = require("../package.json");
  const { version } = packageJson;
  const zipFile = `Clash.Verge_${version}_${arch}_portable.zip`;
  zip.writeZip(zipFile);
  console.log("[INFO]: create portable zip successfully");

  if (process.env.GITHUB_TOKEN === undefined) {
    return;
  }

  const options = { owner: context.repo.owner, repo: context.repo.repo };
  const github = getOctokit(process.env.GITHUB_TOKEN);
  const tag = alpha ? "alpha" : process.env.TAG_NAME || `v${version}`;
  console.log("[INFO]: upload to ", tag);

  const { data: release } = await github.rest.repos.getReleaseByTag({
    ...options,
    tag,
  });

  const assets = release.assets.filter((asset) => asset.name === zipFile);
  if (assets.length > 0) {
    await github.rest.repos.deleteReleaseAsset({
      ...options,
      asset_id: assets[0].id,
    });
  }

  await github.rest.repos.uploadReleaseAsset({
    ...options,
    release_id: release.id,
    name: zipFile,
    data: zip.toBuffer(),
  });
}

resolvePortable().catch(console.error);
