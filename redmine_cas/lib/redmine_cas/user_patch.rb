module RedmineCas
  module UserPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method :original_check_password?, :check_password?
        alias_method :check_password?, :check_password_with_cas?
      end
    end

    module InstanceMethods
      def check_password_with_cas?(clear_password)
        return false if self.auth_source_id == nil && !RedmineCas.local_user_enabled?
        return original_check_password?(clear_password) unless RedmineCas.enabled?
        cas_auth_source = AuthSource.find_by(:name => 'Cas')
        if cas_auth_source.present?
          user = cas_auth_source.authenticate(self.login, clear_password)
          unless user.nil?
            return true
          end
        end

        User.hash_password("#{salt}#{User.hash_password clear_password}") == hashed_password
      end
    end
  end
end