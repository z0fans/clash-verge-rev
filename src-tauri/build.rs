fn main() {
    // Windows 7 兼容性：设置最低子系统版本为 6.1
    #[cfg(all(target_os = "windows", target_env = "msvc"))]
    {
        println!("cargo:rustc-link-arg=/SUBSYSTEM:WINDOWS,6.1");
    }

    tauri_build::build()
}
