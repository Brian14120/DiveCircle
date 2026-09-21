-- DiveCircle Personal Dive Log - PostgreSQL Schema v1
-- Cloud/private web schema
-- Canonical internal units: meters, Celsius, bar, kilograms, seconds

CREATE TABLE users (
  id uuid PRIMARY KEY,
  display_name text,
  locale text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
);

CREATE TABLE diver_profile (
  user_id uuid PRIMARY KEY REFERENCES users(id),
  starting_lifetime_dive_number integer
);

CREATE TABLE devices (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  device_name text,
  platform text,
  last_sync_at timestamptz,
  created_at timestamptz NOT NULL
);

CREATE TABLE user_preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id),
  language_code text,
  locale_code text,
  depth_unit text NOT NULL DEFAULT 'ft',
  visibility_unit text NOT NULL DEFAULT 'ft',
  temperature_unit text NOT NULL DEFAULT 'F',
  pressure_unit text NOT NULL DEFAULT 'psi',
  weight_unit text NOT NULL DEFAULT 'lb',
  time_format text NOT NULL DEFAULT '12h'
);

CREATE TABLE trips (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  name text NOT NULL,
  start_date date,
  end_date date,
  notes text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE dives (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  lifetime_dive_number integer,
  dive_date date,
  trip_id uuid REFERENCES trips(id),
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','LOGGED','VOID')),
  dive_experience_rating smallint CHECK (dive_experience_rating BETWEEN 1 AND 5),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE UNIQUE INDEX ux_dives_user_lifetime_number
ON dives(user_id, lifetime_dive_number)
WHERE status <> 'VOID' AND lifetime_dive_number IS NOT NULL;

CREATE TABLE device_state (
  device_id uuid PRIMARY KEY REFERENCES devices(id),
  user_id uuid NOT NULL REFERENCES users(id),
  current_dive_id uuid REFERENCES dives(id),
  updated_at timestamptz NOT NULL
);

CREATE INDEX ix_dives_user_date ON dives(user_id, dive_date);
CREATE INDEX ix_dives_trip ON dives(trip_id);

CREATE TABLE saved_places (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  place_type text NOT NULL CHECK (place_type IN ('REGION','LODGING','DIVE_SITE')),
  country_code text,
  parent_place_id uuid REFERENCES saved_places(id),
  display_name text NOT NULL,
  community_place_id uuid,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE dive_locations (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL UNIQUE REFERENCES dives(id),
  country_code text,
  country_text text,
  region_place_id uuid REFERENCES saved_places(id),
  region_text text,
  lodging_place_id uuid REFERENCES saved_places(id),
  lodging_text text,
  dive_site_place_id uuid REFERENCES saved_places(id),
  dive_site_text text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE INDEX ix_dive_locations_country ON dive_locations(user_id, country_code);
CREATE INDEX ix_dive_locations_region ON dive_locations(user_id, region_text);
CREATE INDEX ix_dive_locations_lodging ON dive_locations(user_id, lodging_text);
CREATE INDEX ix_dive_locations_site ON dive_locations(user_id, dive_site_text);

CREATE TABLE exposure_options (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  display_name text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  archived boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE accessory_options (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  display_name text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  archived boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE dive_gear (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL UNIQUE REFERENCES dives(id),
  exposure_suit_text text,
  underlayer_text text,
  weight_kg double precision,
  cap_hood_text text,
  gloves_text text,
  boots_text text,
  other_exposure_text text,
  camera_text text,
  knife boolean NOT NULL DEFAULT false,
  backup_knife boolean NOT NULL DEFAULT false,
  dive_light boolean NOT NULL DEFAULT false,
  backup_light boolean NOT NULL DEFAULT false,
  beacon boolean NOT NULL DEFAULT false,
  smb boolean NOT NULL DEFAULT false,
  noise_maker boolean NOT NULL DEFAULT false,
  whistle boolean NOT NULL DEFAULT false,
  compass boolean NOT NULL DEFAULT false,
  slate boolean NOT NULL DEFAULT false,
  gear_comfort_rating smallint CHECK (gear_comfort_rating BETWEEN 1 AND 5),
  gear_notes text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE INDEX ix_dive_gear_exposure ON dive_gear(user_id, exposure_suit_text);
CREATE INDEX ix_dive_gear_rating ON dive_gear(user_id, gear_comfort_rating);

CREATE TABLE dive_gear_accessories (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL REFERENCES dives(id),
  accessory_option_id uuid REFERENCES accessory_options(id),
  accessory_text text,
  sequence integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE tank_definitions (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES users(id),
  display_name text NOT NULL,
  material_code text,
  water_volume_l double precision,
  working_pressure_bar double precision,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE dive_cylinders (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL REFERENCES dives(id),
  sequence integer NOT NULL DEFAULT 1,
  tank_definition_id uuid REFERENCES tank_definitions(id),
  tank_text text,
  oxygen_fraction double precision CHECK (oxygen_fraction IS NULL OR (oxygen_fraction >= 0 AND oxygen_fraction <= 1)),
  helium_fraction double precision CHECK (helium_fraction IS NULL OR (helium_fraction >= 0 AND helium_fraction <= 1)),
  start_pressure_bar double precision,
  end_pressure_bar double precision,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE dive_conditions (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL UNIQUE REFERENCES dives(id),
  day_night text CHECK (day_night IN ('DAY','NIGHT')),
  dive_platform text CHECK (dive_platform IN ('SHORE','BOAT','LIVEABOARD')),
  is_drift boolean,
  surface_condition text CHECK (surface_condition IN ('CLEAR','PARTLY_CLOUDY','CLOUDY','RAINY')),
  surface_air_temp_c double precision,
  water_type text CHECK (water_type IN ('FRESH','SALT')),
  visibility_m double precision,
  visibility_at_least boolean NOT NULL DEFAULT false,
  swell text CHECK (swell IN ('NONE','LOW','MODERATE','HEAVY')),
  current_strength text CHECK (current_strength IN ('NONE','LIGHT','MODERATE','STRONG')),
  surge text CHECK (surge IN ('NONE','LIGHT','MODERATE','STRONG')),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE INDEX ix_conditions_platform ON dive_conditions(user_id, dive_platform);
CREATE INDEX ix_conditions_water_type ON dive_conditions(user_id, water_type);
CREATE INDEX ix_conditions_visibility ON dive_conditions(user_id, visibility_m);
CREATE INDEX ix_conditions_current ON dive_conditions(user_id, current_strength);

CREATE TABLE dive_attributes (
  id uuid PRIMARY KEY,
  code text,
  user_id uuid REFERENCES users(id),
  custom_label text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id),
  CHECK (code IS NOT NULL OR custom_label IS NOT NULL)
);

CREATE UNIQUE INDEX ux_dive_attributes_builtin_code
ON dive_attributes(code)
WHERE user_id IS NULL AND code IS NOT NULL;

CREATE TABLE dive_attribute_links (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL REFERENCES dives(id),
  attribute_id uuid NOT NULL REFERENCES dive_attributes(id),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE UNIQUE INDEX ux_dive_attribute_link
ON dive_attribute_links(dive_id, attribute_id)
WHERE deleted_at IS NULL;

CREATE TABLE dive_data (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL UNIQUE REFERENCES dives(id),
  time_in_local time,
  time_out_local time,
  time_zone_name text,
  utc_offset_minutes integer,
  bottom_time_seconds integer,
  average_depth_m double precision,
  max_depth_m double precision,
  bottom_water_temp_c double precision,
  notes text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE INDEX ix_dive_data_max_depth ON dive_data(user_id, max_depth_m);
CREATE INDEX ix_dive_data_bottom_temp ON dive_data(user_id, bottom_water_temp_c);

CREATE TABLE dive_computers (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  manufacturer text,
  model text,
  serial_number text,
  device_identifier text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE computer_imports (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid REFERENCES dives(id),
  dive_computer_id uuid REFERENCES dive_computers(id),
  external_dive_id text,
  source_format text,
  imported_at timestamptz NOT NULL,
  raw_payload_reference text,
  source_hash text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE INDEX ix_computer_imports_dive ON computer_imports(dive_id);
CREATE INDEX ix_computer_imports_hash ON computer_imports(user_id, source_hash);

CREATE TABLE field_provenance (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  field_name text NOT NULL,
  source_type text NOT NULL CHECK (source_type IN ('MANUAL','IMPORTED','MANUAL_EDIT')),
  source_import_id uuid REFERENCES computer_imports(id),
  original_imported_value_json jsonb,
  manually_edited boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL,
  UNIQUE(user_id, entity_type, entity_id, field_name)
);

CREATE TABLE dive_profile_samples (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  computer_import_id uuid NOT NULL REFERENCES computer_imports(id),
  elapsed_seconds integer NOT NULL,
  depth_m double precision,
  temperature_c double precision,
  tank_pressure_bar double precision,
  heart_rate_bpm integer,
  ascent_rate_m_per_min double precision
);

CREATE INDEX ix_profile_samples_import_time
ON dive_profile_samples(computer_import_id, elapsed_seconds);

CREATE TABLE buddies (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  display_name text NOT NULL,
  linked_user_id uuid REFERENCES users(id),
  notes text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE dive_buddy_links (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL REFERENCES dives(id),
  buddy_id uuid NOT NULL REFERENCES buddies(id),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE UNIQUE INDEX ux_dive_buddy_link
ON dive_buddy_links(dive_id, buddy_id)
WHERE deleted_at IS NULL;

CREATE TABLE dive_verifications (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid NOT NULL REFERENCES dives(id),
  verifier_name text,
  verifier_user_id uuid REFERENCES users(id),
  agency text,
  certification_number text,
  verification_type text,
  verified_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE TABLE media_assets (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  dive_id uuid REFERENCES dives(id),
  trip_id uuid REFERENCES trips(id),
  local_uri text,
  cloud_object_key text,
  media_type text NOT NULL,
  caption text,
  captured_at timestamptz,
  file_checksum text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1,
  origin_device_id uuid REFERENCES devices(id)
);

CREATE INDEX ix_media_dive ON media_assets(dive_id);
CREATE INDEX ix_media_trip ON media_assets(trip_id);
CREATE INDEX ix_media_checksum ON media_assets(user_id, file_checksum);

CREATE TABLE change_history (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  field_name text,
  old_value_json jsonb,
  new_value_json jsonb,
  change_source text,
  device_id uuid REFERENCES devices(id),
  changed_at timestamptz NOT NULL
);

CREATE INDEX ix_change_history_entity
ON change_history(user_id, entity_type, entity_id, changed_at);

-- Seed built-in dive attributes in a migration:
-- REEF, WRECK, WALL, PINNACLE, PASS_THROUGH, MUCK, SANDY_BOTTOM

-- Dive Notes full-text search:
ALTER TABLE dive_data ADD COLUMN notes_search tsvector
  GENERATED ALWAYS AS (to_tsvector('simple', coalesce(notes, ''))) STORED;
CREATE INDEX ix_dive_data_notes_search ON dive_data USING gin(notes_search);
