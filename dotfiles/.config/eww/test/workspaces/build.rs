fn main() {
    pkg_config::Config::new().probe("x11").unwrap();
}