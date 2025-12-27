use clap::{Parser, Subcommand};
use reqwest::blocking::Client;
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use std::fmt::Debug;
use std::time::Duration;

#[derive(Serialize, Deserialize, Debug)]
struct Song {
    name: String,
    author: String,
    url: String,
    cover_art: String,
    is_paused: bool,
    duration: Duration,
    elapsed: Duration,
    volume: u8,
}

#[derive(Debug)]
struct APIError {}

struct APIClient {
    base_url: String,
    client: Client,
}

impl APIClient {
    fn new(base_url: String) -> Self {
        Self {
            base_url,
            client: Client::new(),
        }
    }

    fn get<T: DeserializeOwned>(&self, url: &str) -> Result<T, APIError> {
        self.client
            .get(self.base_url.to_owned() + "/" + url)
            .send()
            .map(|r| r.json::<T>())
            .and_then(|r| r)
            .map_err(|_| APIError {})
    }

    // fn get(&self, url: &str) -> Result<String, APIError> {
    //     self.client
    //         .get(self.base_url.to_owned() + "/" + url)
    //         .send()
    //         .map(|r| r.text())
    //         .and_then(|r| r)
    //         .map_err(|_| APIError {})
    // }

    fn post<TPayload: Serialize + ?Sized, TResponse: DeserializeOwned>(
        &self,
        url: &str,
        payload: &TPayload,
    ) -> Result<TResponse, APIError> {
        let request = self
            .client
            .post(self.base_url.to_owned() + "/" + url)
            .json(&payload);
        request
            .send()
            .map(|r| r.json::<TResponse>())
            .and_then(|r| r)
            .map_err(|_| APIError {})
    }
}

trait APIBackend {
    fn get_song_data(&self) -> Result<Song, APIError>;
    fn play(&self) -> Result<(), APIError>;
    fn pause(&self) -> Result<(), APIError>;
    fn toggle(&self) -> Result<(), APIError>;
    fn set_time(&self, time: Duration) -> Result<(), APIError>;
    fn next(&self) -> Result<(), APIError>;
    fn prev(&self) -> Result<(), APIError>;
    fn set_volume(&self, volume: u8) -> Result<(), APIError>;
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SongInfoDTO {
    pub title: String,
    pub artist: String,
    pub views: u64,
    pub image_src: String,
    pub is_paused: bool,
    pub song_duration: u64,
    pub elapsed_seconds: u64,
    pub url: String,
    pub video_id: String,
    pub playlist_id: String,
    pub media_type: String,
    pub album: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct VolumeDTO {
    pub state: u8,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SetVolumeDTO {
    pub volume: u8,
}

struct YTMusicBackend {
    client: APIClient,
}

impl YTMusicBackend {
    fn new(host: &str, port: u32) -> Self {
        let base_url = format!("http://{host}:{port}/api/v1");
        Self {
            client: APIClient::new(base_url),
        }
    }
}

#[derive(Deserialize, Serialize)]
struct SetTimePayload {
    seconds: u64,
}

impl APIBackend for YTMusicBackend {
    fn get_song_data(&self) -> Result<Song, APIError> {
        let song_info = self.client.get::<SongInfoDTO>("song")?;
        let volume = self.client.get::<VolumeDTO>("volume")?;
        Ok(Song {
            name: song_info.title,
            author: song_info.artist,
            url: song_info.url,
            cover_art: song_info.image_src,
            is_paused: song_info.is_paused,
            duration: Duration::from_secs(song_info.song_duration),
            elapsed: Duration::from_secs(song_info.elapsed_seconds),
            volume: volume.state,
        })
    }

    fn play(&self) -> Result<(), APIError> {
        todo!()
    }

    fn pause(&self) -> Result<(), APIError> {
        todo!()
    }

    fn toggle(&self) -> Result<(), APIError> {
        self.client.post("toggle-play", &())
    }

    fn set_time(&self, time: Duration) -> Result<(), APIError> {
        self.client.post(
            "seek-to",
            &SetTimePayload {
                seconds: time.as_secs(),
            },
        )
    }

    fn set_volume(&self, volume: u8) -> Result<(), APIError> {
        self.client.post("volume", &SetVolumeDTO { volume })
    }

    fn next(&self) -> Result<(), APIError> {
        self.client.post("next", &())
    }

    fn prev(&self) -> Result<(), APIError> {
        self.client.post("previous", &())
    }
}

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    SongInfo,
    Toggle,
    Prev,
    Next,
    SetTime { seconds: u64 },
    SetVolume { volume: u8 },
}

fn dispatch_cli(cli: Cli, backend: Box<dyn APIBackend>) -> Result<Option<String>, APIError> {
    match &cli.command {
        Some(Commands::SongInfo) => {
            let song_info = backend.get_song_data()?;
            let a = serde_json::to_string(&song_info).map_err(|_| APIError {})?;
            Ok(Some(a))
        }
        Some(Commands::Toggle) => {
            backend.toggle()?;
            Ok(None)
        }
        Some(Commands::Prev) => {
            backend.prev()?;
            Ok(None)
        }
        Some(Commands::Next) => {
            backend.next()?;
            Ok(None)
        }
        Some(Commands::SetTime { seconds }) => {
            backend.set_time(Duration::from_secs(seconds.to_owned()))?;
            Ok(None)
        }
        Some(Commands::SetVolume { volume }) => {
            backend.set_volume(volume.to_owned())?;
            Ok(None)
        }
        None => Ok(None),
    }
}

fn main() {
    let yt = YTMusicBackend::new("0.0.0.0", 26538);
    let cli = Cli::parse();
    let result = dispatch_cli(cli, Box::new(yt));
    match result {
        Ok(Some(res)) => {
            println!("{res}");
        }
        Err(_) => {
            eprintln!("Error ocured while ");
        }
        _ => (),
    }
}
