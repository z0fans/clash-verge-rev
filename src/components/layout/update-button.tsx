// 禁用自动更新 - Win7 Legacy
// import useSWR from "swr";
// import { useRef } from "react";
// import { Button } from "@mui/material";
// import { check } from "@tauri-apps/plugin-updater";
// import { UpdateViewer } from "../setting/mods/update-viewer";
// import { DialogRef } from "../base";
// import { useVerge } from "@/hooks/use-verge";

interface Props {
  className?: string;
}

export const UpdateButton = (props: Props) => {
  // 始终返回 null，不显示更新按钮
  return null;
};
