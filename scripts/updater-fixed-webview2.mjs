import fetch from "node-fetch";
import { getOctokit, context } from "@actions/github";

const UPDATE_TAG_NAME = "updater";
const UPDATE_JSON_FILE = "update-fixed-webview2.json";
const UPDATE_JSON_PROXY = "update-fixed-webview2-proxy.json";

function getVersionFromTag(tagName) {
  return tagName.startsWith("v") ? tagName.slice(1) : tagName;
}

function resolveReleaseNotes(releaseBody) {
  if (releaseBody && releaseBody.trim()) {
    return releaseBody.trim();
  }

  return "No changelog available";
}

function normalizeRefTag(refValue = "") {
  if (!refValue) {
    return "";
  }

  return refValue.startsWith("refs/tags/")
    ? refValue.slice("refs/tags/".length)
    : refValue;
}

async function resolveLatestStableRelease(github, options, preferredTag) {
  const stableRegex = /^v\d+\.\d+\.\d+$/;

  if (preferredTag && stableRegex.test(preferredTag)) {
    try {
      const response = await github.rest.repos.getReleaseByTag({
        ...options,
        tag: preferredTag,
      });
      return { tagName: preferredTag, release: response.data };
    } catch (error) {
      if (error.status !== 404) {
        throw error;
      }
    }
  }

  const tags = [];
  let page = 1;
  const perPage = 100;

  while (true) {
    const { data: pageTags } = await github.rest.repos.listTags({
      ...options,
      per_page: perPage,
      page,
    });

    tags.push(...pageTags);
    if (pageTags.length < perPage) {
      break;
    }
    page++;
  }

  for (const item of tags) {
    if (!stableRegex.test(item.name)) {
      continue;
    }

    try {
      const response = await github.rest.repos.getReleaseByTag({
        ...options,
        tag: item.name,
      });
      return { tagName: item.name, release: response.data };
    } catch (error) {
      if (error.status !== 404) {
        throw error;
      }
    }
  }

  throw new Error("No stable release found for updater-fixed-webview2");
}

async function resolveUpdater() {
  if (!process.env.GITHUB_TOKEN) {
    throw new Error("GITHUB_TOKEN is required");
  }

  const options = { owner: context.repo.owner, repo: context.repo.repo };
  const github = getOctokit(process.env.GITHUB_TOKEN);

  const preferredTag = normalizeRefTag(
    process.env.GITHUB_REF_NAME || process.env.GITHUB_REF || "",
  );
  const { tagName, release: latestRelease } = await resolveLatestStableRelease(
    github,
    options,
    preferredTag,
  );

  const updateData = {
    version: getVersionFromTag(tagName),
    notes: resolveReleaseNotes(latestRelease.body),
    pub_date: new Date().toISOString(),
    platforms: {
      "windows-x86_64": { signature: "", url: "" },
      "windows-aarch64": { signature: "", url: "" },
      "windows-x86": { signature: "", url: "" },
      "windows-i686": { signature: "", url: "" },
    },
  };

  const promises = latestRelease.assets.map(async (asset) => {
    const { name, browser_download_url } = asset;

    // win64 url
    if (name.endsWith("x64_fixed_webview2-setup.exe")) {
      updateData.platforms["windows-x86_64"].url = browser_download_url;
    }
    // win64 signature
    if (name.endsWith("x64_fixed_webview2-setup.exe.sig")) {
      const sig = await getSignature(browser_download_url);
      updateData.platforms["windows-x86_64"].signature = sig;
    }

    // win32 url
    if (name.endsWith("x86_fixed_webview2-setup.exe")) {
      updateData.platforms["windows-x86"].url = browser_download_url;
      updateData.platforms["windows-i686"].url = browser_download_url;
    }
    // win32 signature
    if (name.endsWith("x86_fixed_webview2-setup.exe.sig")) {
      const sig = await getSignature(browser_download_url);
      updateData.platforms["windows-x86"].signature = sig;
      updateData.platforms["windows-i686"].signature = sig;
    }

    // win arm url
    if (name.endsWith("arm64_fixed_webview2-setup.exe")) {
      updateData.platforms["windows-aarch64"].url = browser_download_url;
    }
    // win arm signature
    if (name.endsWith("arm64_fixed_webview2-setup.exe.sig")) {
      const sig = await getSignature(browser_download_url);
      updateData.platforms["windows-aarch64"].signature = sig;
    }
  });

  await Promise.allSettled(promises);
  console.log(updateData);

  // maybe should test the signature as well
  // delete the null field
  Object.entries(updateData.platforms).forEach(([key, value]) => {
    if (!value.url || !value.signature) {
      console.log(`[Error]: failed to parse release for "${key}"`);
      delete updateData.platforms[key];
    }
  });

  if (Object.keys(updateData.platforms).length === 0) {
    throw new Error("No fixed-webview2 platform assets were resolved");
  }

  // 生成一个代理github的更新文件
  // 使用 https://hub.fastgit.xyz/ 做github资源的加速
  const updateDataNew = JSON.parse(JSON.stringify(updateData));

  Object.entries(updateDataNew.platforms).forEach(([key, value]) => {
    if (value.url) {
      updateDataNew.platforms[key].url =
        "https://download.clashverge.dev/" + value.url;
    } else {
      console.log(`[Error]: updateDataNew.platforms.${key} is null`);
    }
  });

  // update the update.json
  let updateRelease;
  try {
    const response = await github.rest.repos.getReleaseByTag({
      ...options,
      tag: UPDATE_TAG_NAME,
    });
    updateRelease = response.data;
  } catch (error) {
    if (error.status !== 404) {
      throw error;
    }

    const created = await github.rest.repos.createRelease({
      ...options,
      tag_name: UPDATE_TAG_NAME,
      name: "Auto-update Stable Channel",
      body: "This release contains the update information for stable channel.",
      prerelease: false,
    });
    updateRelease = created.data;
  }

  // delete the old assets
  for (let asset of updateRelease.assets) {
    if (asset.name === UPDATE_JSON_FILE) {
      await github.rest.repos.deleteReleaseAsset({
        ...options,
        asset_id: asset.id,
      });
    }

    if (asset.name === UPDATE_JSON_PROXY) {
      await github.rest.repos
        .deleteReleaseAsset({ ...options, asset_id: asset.id })
        .catch(console.error); // do not break the pipeline
    }
  }

  // upload new assets
  await github.rest.repos.uploadReleaseAsset({
    ...options,
    release_id: updateRelease.id,
    name: UPDATE_JSON_FILE,
    data: JSON.stringify(updateData, null, 2),
  });

  await github.rest.repos.uploadReleaseAsset({
    ...options,
    release_id: updateRelease.id,
    name: UPDATE_JSON_PROXY,
    data: JSON.stringify(updateDataNew, null, 2),
  });
}

// get the signature file content
async function getSignature(url) {
  const response = await fetch(url, {
    method: "GET",
    headers: { "Content-Type": "application/octet-stream" },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch signature: ${response.status} ${url}`);
  }

  return response.text();
}

resolveUpdater().catch((error) => {
  console.error(error);
  process.exit(1);
});
