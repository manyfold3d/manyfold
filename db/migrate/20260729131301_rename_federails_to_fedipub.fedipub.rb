# This migration comes from fedipub (originally 20260723113716)
class RenameFederailsToFedipub < ActiveRecord::Migration[7.2]
  def change
    # Activities
    rename_index "federails_activities", "index_federails_activities_on_entity", "index_fedipub_activities_on_entity"
    rename_table "federails_activities", "fedipub_activities"
    # Actors
    rename_index "federails_actors", "index_federails_actors_on_entity", "index_fedipub_actors_on_entity"
    rename_table "federails_actors", "fedipub_actors"
    # Followings
    rename_index "federails_followings", "index_federails_followings_on_actor_id_and_target_actor_id", "index_fedipub_followings_on_actor_id_and_target_actor_id"
    rename_table "federails_followings", "fedipub_followings"
    # Hosts
    rename_table "federails_hosts", "fedipub_hosts"
  end
end
