defmodule Philomena.Repo.Migrations.RewriteSourceChanges do
  use Ecto.Migration

  def change do
    create table(:new_source_changes) do
      add :image_id, references(:images), null: false
      add :user_id, references(:users)
      add :ip, :inet, null: false
      timestamps(inserted_at: :created_at)

      add :fingerprint, :string
      add :user_agent, :string, default: ""
      add :referrer, :string, default: ""
      add :value, :string, null: false
      add :added, :boolean, null: false
    end

    alter table (:image_sources) do
      modify(:source, :string, from: :text, size: 255)
      drop constraint(:length_must_be_valid, check: "length(source) >= 8 and length(source) <= 1024")
      add constraint(:image_sources_source_check, check: "substr(source, 1, 7) = 'http://' or substr(source, 1, 8) = 'https://'")
    end

    if direction() == :up do
      execute("""
      insert into image_sources (image_id, source)
      select id, substr(source_url, 1, 255) from images
      where source_url is not null and substr(source_url, 1, 7) = 'http://' or substr(source_url, 1, 8) = 'https://';
      """)

      # First insert the "added" changes...
      execute("""
      with ranked_added_source_changes as (
        select
          image_id, user_id, ip, created_at, updated_at, fingerprint, user_agent,
          substr(referrer, 1, 255) as referrer,
          substr(new_value, 1, 255) as value, true as added,
          rank() over (partition by image_id order by created_at asc)
          from source_changes
          where new_value is not null
      )
      insert into new_source_changes
      (image_id, user_id, ip, created_at, updated_at, fingerprint, user_agent, referrer, value, added)
      select image_id, user_id, ip, created_at, updated_at, fingerprint, user_agent, referrer, value, added
      from ranked_added_source_changes
      where "rank" > 1;
      """)

      # ...then the "removed" changes
      execute("""
      with ranked_removed_source_changes as (
        select
          image_id, user_id, ip, created_at, updated_at, fingerprint, user_agent,
          substr(referrer, 1, 255) as referrer,
          substr(new_value, 1, 255) as value, false as added,
          rank() over (partition by image_id order by created_at desc)
          from source_changes
          where new_value is not null
      )
      insert into new_source_changes
      (image_id, user_id, ip, created_at, updated_at, fingerprint, user_agent, referrer, value, added)
      select image_id, user_id, ip, created_at, updated_at, fingerprint, user_agent, referrer, value, added
      from ranked_removed_source_changes
      where "rank" > 1;
      """)
    else if direction() == :down
      execute("""
      truncate new_source_changes;
      truncate image_sources;
      """)
    end

    rename table(:source_changes), to: table(:old_source_changes)
    rename table(:new_source_changes), to: table(:source_changes)
  end
end
