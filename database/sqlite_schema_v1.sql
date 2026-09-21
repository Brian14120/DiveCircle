-- DiveCircle Personal Dive Log - SQLite Schema v1
-- Local-first device database
-- Canonical internal units: meters, Celsius, bar, kilograms, seconds

PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id TEXT PRIMARY KEY,
  display_name TEXT,
  locale TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  device_name TEXT,
  platform TEXT,
  last_sync_at TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE user_preferences (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  language_code TEXT,
  locale_code TEXT,
  depth_unit TEXT NOT NULL DEFAULT 'ft',
  visibility_unit TEXT NOT NULL DEFAULT 'ft',
  temperature_unit TEXT NOT NULL DEFAULT 'F',
  pressure_unit TEXT NOT NULL DEFAULT 'psi',
  weight_unit TEXT NOT NULL DEFAULT 'lb',
  time_format TEXT NOT NULL DEFAULT '12h',
  next_lifetime_dive_number INTEGER,
  current_dive_id TEXT
);

CREATE TABLE trips (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  start_date TEXT,
  end_date TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE dives (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  lifetime_dive_number INTEGER,
  dive_date TEXT,
  trip_id TEXT REFERENCES trips(id),
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','LOGGED','VOID')),
  dive_experience_rating INTEGER CHECK (dive_experience_rating BETWEEN 1 AND 5),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE UNIQUE INDEX ux_dives_user_lifetime_number
ON dives(user_id, lifetime_dive_number)
WHERE status <> 'VOID' AND lifetime_dive_number IS NOT NULL;

CREATE INDEX ix_dives_user_date ON dives(user_id, dive_date);
CREATE INDEX ix_dives_trip ON dives(trip_id);

CREATE TABLE saved_places (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  place_type TEXT NOT NULL CHECK (place_type IN ('REGION','LODGING','DIVE_SITE')),
  country_code TEXT,
  parent_place_id TEXT REFERENCES saved_places(id),
  display_name TEXT NOT NULL,
  community_place_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE dive_locations (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL UNIQUE REFERENCES dives(id),
  country_code TEXT,
  country_text TEXT,
  region_place_id TEXT REFERENCES saved_places(id),
  region_text TEXT,
  lodging_place_id TEXT REFERENCES saved_places(id),
  lodging_text TEXT,
  dive_site_place_id TEXT REFERENCES saved_places(id),
  dive_site_text TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE INDEX ix_dive_locations_country ON dive_locations(user_id, country_code);
CREATE INDEX ix_dive_locations_region ON dive_locations(user_id, region_text);
CREATE INDEX ix_dive_locations_lodging ON dive_locations(user_id, lodging_text);
CREATE INDEX ix_dive_locations_site ON dive_locations(user_id, dive_site_text);

CREATE TABLE exposure_options (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  display_name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE accessory_options (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  display_name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE dive_gear (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL UNIQUE REFERENCES dives(id),
  exposure_suit_text TEXT,
  underlayer_text TEXT,
  weight_kg REAL,
  cap_hood_text TEXT,
  gloves_text TEXT,
  boots_text TEXT,
  other_exposure_text TEXT,
  camera_text TEXT,
  knife INTEGER NOT NULL DEFAULT 0 CHECK (knife IN (0,1)),
  backup_knife INTEGER NOT NULL DEFAULT 0 CHECK (backup_knife IN (0,1)),
  dive_light INTEGER NOT NULL DEFAULT 0 CHECK (dive_light IN (0,1)),
  backup_light INTEGER NOT NULL DEFAULT 0 CHECK (backup_light IN (0,1)),
  beacon INTEGER NOT NULL DEFAULT 0 CHECK (beacon IN (0,1)),
  smb INTEGER NOT NULL DEFAULT 0 CHECK (smb IN (0,1)),
  noise_maker INTEGER NOT NULL DEFAULT 0 CHECK (noise_maker IN (0,1)),
  whistle INTEGER NOT NULL DEFAULT 0 CHECK (whistle IN (0,1)),
  compass INTEGER NOT NULL DEFAULT 0 CHECK (compass IN (0,1)),
  slate INTEGER NOT NULL DEFAULT 0 CHECK (slate IN (0,1)),
  gear_comfort_rating INTEGER CHECK (gear_comfort_rating BETWEEN 1 AND 5),
  gear_notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE INDEX ix_dive_gear_exposure ON dive_gear(user_id, exposure_suit_text);
CREATE INDEX ix_dive_gear_rating ON dive_gear(user_id, gear_comfort_rating);

CREATE TABLE dive_gear_accessories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL REFERENCES dives(id),
  accessory_option_id TEXT REFERENCES accessory_options(id),
  accessory_text TEXT,
  sequence INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE tank_definitions (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id),
  display_name TEXT NOT NULL,
  material_code TEXT,
  water_volume_l REAL,
  working_pressure_bar REAL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE dive_cylinders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL REFERENCES dives(id),
  sequence INTEGER NOT NULL DEFAULT 1,
  tank_definition_id TEXT REFERENCES tank_definitions(id),
  tank_text TEXT,
  oxygen_fraction REAL CHECK (oxygen_fraction IS NULL OR (oxygen_fraction >= 0 AND oxygen_fraction <= 1)),
  helium_fraction REAL CHECK (helium_fraction IS NULL OR (helium_fraction >= 0 AND helium_fraction <= 1)),
  start_pressure_bar REAL,
  end_pressure_bar REAL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE dive_conditions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL UNIQUE REFERENCES dives(id),
  day_night TEXT CHECK (day_night IN ('DAY','NIGHT')),
  dive_platform TEXT CHECK (dive_platform IN ('SHORE','BOAT','LIVEABOARD')),
  is_drift INTEGER CHECK (is_drift IN (0,1)),
  surface_condition TEXT CHECK (surface_condition IN ('CLEAR','PARTLY_CLOUDY','CLOUDY','RAINY')),
  surface_air_temp_c REAL,
  water_type TEXT CHECK (water_type IN ('FRESH','SALT')),
  visibility_m REAL,
  visibility_at_least INTEGER NOT NULL DEFAULT 0 CHECK (visibility_at_least IN (0,1)),
  swell TEXT CHECK (swell IN ('NONE','LOW','MODERATE','HEAVY')),
  current_strength TEXT CHECK (current_strength IN ('NONE','LIGHT','MODERATE','STRONG')),
  surge TEXT CHECK (surge IN ('NONE','LIGHT','MODERATE','STRONG')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE INDEX ix_conditions_platform ON dive_conditions(user_id, dive_platform);
CREATE INDEX ix_conditions_water_type ON dive_conditions(user_id, water_type);
CREATE INDEX ix_conditions_visibility ON dive_conditions(user_id, visibility_m);
CREATE INDEX ix_conditions_current ON dive_conditions(user_id, current_strength);

CREATE TABLE dive_attributes (
  id TEXT PRIMARY KEY,
  code TEXT,
  user_id TEXT REFERENCES users(id),
  custom_label TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id),
  CHECK (code IS NOT NULL OR custom_label IS NOT NULL)
);

CREATE UNIQUE INDEX ux_dive_attributes_builtin_code
ON dive_attributes(code)
WHERE user_id IS NULL AND code IS NOT NULL;

CREATE TABLE dive_attribute_links (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL REFERENCES dives(id),
  attribute_id TEXT NOT NULL REFERENCES dive_attributes(id),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE UNIQUE INDEX ux_dive_attribute_link
ON dive_attribute_links(dive_id, attribute_id)
WHERE deleted_at IS NULL;

CREATE TABLE dive_data (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL UNIQUE REFERENCES dives(id),
  time_in_local TEXT,
  time_out_local TEXT,
  time_zone_name TEXT,
  utc_offset_minutes INTEGER,
  bottom_time_seconds INTEGER,
  average_depth_m REAL,
  max_depth_m REAL,
  bottom_water_temp_c REAL,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE INDEX ix_dive_data_max_depth ON dive_data(user_id, max_depth_m);
CREATE INDEX ix_dive_data_bottom_temp ON dive_data(user_id, bottom_water_temp_c);

CREATE TABLE dive_computers (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  manufacturer TEXT,
  model TEXT,
  serial_number TEXT,
  device_identifier TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE computer_imports (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT REFERENCES dives(id),
  dive_computer_id TEXT REFERENCES dive_computers(id),
  external_dive_id TEXT,
  source_format TEXT,
  imported_at TEXT NOT NULL,
  raw_payload_reference TEXT,
  source_hash TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE INDEX ix_computer_imports_dive ON computer_imports(dive_id);
CREATE INDEX ix_computer_imports_hash ON computer_imports(user_id, source_hash);

CREATE TABLE field_provenance (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  field_name TEXT NOT NULL,
  source_type TEXT NOT NULL CHECK (source_type IN ('MANUAL','IMPORTED','MANUAL_EDIT')),
  source_import_id TEXT REFERENCES computer_imports(id),
  original_imported_value_json TEXT,
  manually_edited INTEGER NOT NULL DEFAULT 0 CHECK (manually_edited IN (0,1)),
  updated_at TEXT NOT NULL,
  UNIQUE(user_id, entity_type, entity_id, field_name)
);

CREATE TABLE dive_profile_samples (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  computer_import_id TEXT NOT NULL REFERENCES computer_imports(id),
  elapsed_seconds INTEGER NOT NULL,
  depth_m REAL,
  temperature_c REAL,
  tank_pressure_bar REAL,
  heart_rate_bpm INTEGER,
  ascent_rate_m_per_min REAL
);

CREATE INDEX ix_profile_samples_import_time
ON dive_profile_samples(computer_import_id, elapsed_seconds);

CREATE TABLE buddies (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  display_name TEXT NOT NULL,
  linked_user_id TEXT REFERENCES users(id),
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE dive_buddy_links (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL REFERENCES dives(id),
  buddy_id TEXT NOT NULL REFERENCES buddies(id),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE UNIQUE INDEX ux_dive_buddy_link
ON dive_buddy_links(dive_id, buddy_id)
WHERE deleted_at IS NULL;

CREATE TABLE dive_verifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT NOT NULL REFERENCES dives(id),
  verifier_name TEXT,
  verifier_user_id TEXT REFERENCES users(id),
  agency TEXT,
  certification_number TEXT,
  verification_type TEXT,
  verified_at TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE TABLE media_assets (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dive_id TEXT REFERENCES dives(id),
  trip_id TEXT REFERENCES trips(id),
  local_uri TEXT,
  cloud_object_key TEXT,
  media_type TEXT NOT NULL,
  caption TEXT,
  captured_at TEXT,
  file_checksum TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  revision INTEGER NOT NULL DEFAULT 1,
  origin_device_id TEXT REFERENCES devices(id)
);

CREATE INDEX ix_media_dive ON media_assets(dive_id);
CREATE INDEX ix_media_trip ON media_assets(trip_id);
CREATE INDEX ix_media_checksum ON media_assets(user_id, file_checksum);

CREATE TABLE change_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  field_name TEXT,
  old_value_json TEXT,
  new_value_json TEXT,
  change_source TEXT,
  device_id TEXT REFERENCES devices(id),
  changed_at TEXT NOT NULL
);

CREATE INDEX ix_change_history_entity
ON change_history(user_id, entity_type, entity_id, changed_at);

-- Initial built-in dive attributes should be seeded by migration:
-- REEF, WRECK, WALL, PINNACLE, PASS_THROUGH, MUCK, SANDY_BOTTOM

-- Dive Notes full-text search:
CREATE VIRTUAL TABLE IF NOT EXISTS dive_notes_fts
USING fts5(dive_id UNINDEXED, notes);
