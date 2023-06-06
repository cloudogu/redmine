module RedmineCas
  class UserManager
    def self.update_cas_admin_value(user, new_value)
      user.custom_field_values.each do |field|
        field.value = new_value if field.custom_field.name == 'casAdmin'
      end
    end

    # Returns the group by name and creates if it does not already exist
    def self.get_group(groupname)
      group = Group.find_by(lastname: groupname)
      return group unless group.nil?

      group = Group.new(:lastname => groupname, :firstname => 'cas')
      group.save!
      group
    end

    def self.add_user_to_group(group, user)
      begin
        Rails.logger.debug "add_user_to_group: " + group.to_s + ", " + user.to_s

        # if not already: add user to existing group
        if User.where(id: user.id).in_group(group).empty?
          Rails.logger.info 'add "' + user.to_s + '" to group ' + group.to_s
          group.users << user
          group.save!
        else
          Rails.logger.info '"' + user.to_s + '" is already member of "' + group.to_s + '"'
        end

      rescue Exception => e
        Rails.logger.info e.message
      end
    end

    def self.create_or_update_user(login, first_name, last_name, mail, user_groups)
      ces_admin_group=RedmineCas.get_admin_group
      user = User.find_by_login(login)
      cas_auth_source = AuthSource.find_by(:name => 'Cas')

      # Get ces admin group
      admin_group_exists = false
      if ces_admin_group != ''
        admin_group_exists = true
      end

      if user == nil # user not in redmine yet
        user = User.new
        user.login = login
        user.firstname = first_name
        user.lastname = last_name
        user.mail = mail
        user.auth_source_id = cas_auth_source.id unless cas_auth_source.nil?

        for groupname in user_groups
          group = self.get_group(groupname)
          self.add_user_to_group(group, user)
        end unless user_groups.nil?

      else
        # user already exists
        self.update_user_groups(user, user_groups)
      end

      if admin_group_exists
        user_should_be_admin = user_groups.to_s.include?(ces_admin_group.to_s.gsub('\n', ''))
        cas_admin_field = RedmineCas.create_or_update_cas_admin_custom_field
        admin_permissions_set_by_cas = user.custom_field_value(cas_admin_field).is_true?

        # Grant admin rights to user if he/she is in ces_admin_group
        # Revoke admin rights if they were granted by cas and not granted from a redmine administrator
        if user_should_be_admin
          self.update_cas_admin_value(user, 1) if user.admin.is_false? && user_should_be_admin
          user.admin = 1
        else
          self.update_cas_admin_value(user, 0) if admin_permissions_set_by_cas
          user.admin = 0 if admin_permissions_set_by_cas
        end
      end

      if !user.save
        raise user.errors.full_messages.to_s
      end

      user
    end

    def self.update_user_groups(user, user_groups)
      for groupname in user_groups
        group = self.get_group(groupname)
        self.add_user_to_group(group, user)
      end unless user_groups.nil?

      groups_to_remove = Group.joins(:users)
                              .left_outer_joins(:groups_users)
                              .where(groups_users: { user_id: user.id })
                              .where(users: { firstname: 'cas' })
                              .where.not(lastname: user_groups)
                              .distinct

      for group in groups_to_remove
        group.users.delete(user)
      end

    end

  end
end