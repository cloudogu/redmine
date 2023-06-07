module RedmineCas
  module ApplicationControllerPatch
    def self.included(base)
      base.send(:prepend, InstanceMethods)
    end

    module InstanceMethods
      def user_setup
        super
        # reload user data so the updated group information will be took into account
        User.current.reload
      end

      def find_current_user
        if /\AProxyTicket /i.match?(request.authorization.to_s)
          begin
            ticket = request.authorization.to_s.split(" ", 2)[1]
            service = RedmineCas.get_redmine_url
            pt = CASClient::ServiceTicket.new(ticket, service)
            validationResponse = CASClient::Frameworks::Rails::Filter.client.validate_proxy_ticket(pt)
            if validationResponse.success
              login = validationResponse.user

              userAttributes = validationResponse.extra_attributes
              user_mail = userAttributes["mail"]
              user_surname = userAttributes["surname"]
              user_givenName = userAttributes["givenName"]
              user_groups = userAttributes["allgroups"]

              user = RedmineCas::UserManager.create_or_update_user(login, user_givenName, user_surname, user_mail, user_groups)

              return user
            end
          rescue => e
            puts "error while validating proxy ticket"
            puts e.to_s
          end
        end

        super
      end

      def require_login
        return super unless RedmineCas.enabled?

        unless User.current.logged?
          referrer = request.fullpath
          respond_to do |format|
            # pass referer to cas action, to work around this problem:
            # https://github.com/ninech/redmine_cas/pull/13#issuecomment-53697288
            format.html { redirect_to :controller => 'account', :action => 'cas', :ref => referrer }
            format.atom { redirect_to :controller => 'account', :action => 'cas', :ref => referrer }
            format.xml { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
            format.js { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
            format.json { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
          end
          return false
        end
        # this code was added to remove the ticket parameter in url when it is not necessary
        if params.has_key?(:ticket)
          default_url = url_for(params.permit(:ticket).merge(:ticket => nil))
          redirect_to default_url
        end
        true
      end

      def check_if_login_required
        return super unless RedmineCas.enabled?
        require_login if params.has_key?(:ticket) or super
      end

      def verify_authenticity_token
        if logout_request?
          logger.info 'CAS logout request detected: Skipping validation of authenticity token'
        else
          super
        end
      end

      def logout_request?
        request.post? && params.has_key?('logoutRequest')
      end

    end
  end
end
