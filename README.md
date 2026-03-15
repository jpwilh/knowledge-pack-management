# Knowledge Pack Management

This project manages the automated download and maintenance of a comprehensive **Offline Knowledge Pack** (~1 TB), designed for emergency preparedness and education in environments without internet access.

## Features

- **Automated Downloads**: Downloads high-quality ZIM archives (Wikipedia, Khan Academy, Stack Exchange) and PDF resources (FAO, medical guides).
- **Hybrid Content**: Includes both German (DE) and English (EN) resources.
- **Resilience**:
  - `offline_knowledge_pack.sh`: Main download engine with retry logic and file validation.
  - `watchdog.sh`: Monitors the download process and restarts it automatically if it crashes.
  - `status.sh`: Provides a quick overview of the current download progress.
  - `traffic.sh`: Monitors network usage.

## Installation & Configuration

### Prerequisites

- Linux (Ubuntu/Debian recommended)
- `curl` and `wget`
- A large external storage drive (at least 1 TB)

### Setup Environment

The scripts expect the environment variable `EXTERNAL_DRIVE` to be set to your mount point. You can add this to your `~/.bashrc`:

```bash
export EXTERNAL_DRIVE="/media/jpw/YOUR_DRIVE_NAME"
source ~/.bashrc
```

## Usage

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jpwilh/knowledge-pack-management.git
   cd knowledge-pack-management
   ```

2. **Start the watchdog** (recommended for large downloads):
   ```bash
   ./watchdog.sh
   ```

3. **Check status**:
   ```bash
   ./status.sh
   ```
