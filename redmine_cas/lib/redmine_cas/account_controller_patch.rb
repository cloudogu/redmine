module RedmineCas
  module AccountControllerPatch
    def self.included(base)
      base.send(:include, NewMethods)
      base.send(:prepend, InstanceMethods)
    end

    module NewMethods
      def cas
        return redirect_to_action('login') unless RedmineCas.enabled?

        if User.current.logged?
          # User already logged in.
          redirect_to home_url
          return
        end

        if CASClient::Frameworks::Rails::Filter.filter(self)
          attrs = RedmineCas.user_extra_attributes_from_session(session)
          user = RedmineCas::UserManager.create_or_update_user(attrs["login"], attrs["firstname"], attrs["lastname"], attrs["mail"], attrs["allgroups"])
          return cas_user_not_found if user.nil?
          return cas_account_pending unless user.active?

          user.last_login_on = Time.now
          user.save!

          if RedmineCas.single_sign_out_enabled?
            # logged_user= would start a new session and break single sign-out
            User.current = user
            start_user_session(user)
          else
            self.logged_user = user
          end

          redirect_to_ref_or_default
        end
      end

      def redirect_to_ref_or_default
        default_url = url_for(params.permit(:ticket).merge(:ticket => nil))
        redirect_url = request.original_url
        if params.has_key?(:ref)
          # do some basic validation on ref, to prevent a malicious link to redirect
          # to another site.
          new_url = params[:ref]
          if /http(s)?:\/\/|@/ =~ new_url
            # evil referrer!
            redirect_url = default_url
          else
            redirect_url = request.base_url + params[:ref]
          end
        else
          redirect_url = default_url
        end
        redirect_to redirect_url unless redirect_url == request.original_url
      end

      def cas_account_pending
        render_custom_403 :message => l(:notice_account_pending)
      end

      def cas_user_not_found
        render_custom_403 :message => l(:redmine_cas_user_not_found, :user => session[:cas_user])
      end

      def cas_user_not_created(user)
        logger.error "Could not auto-create user: #{user.errors.full_messages.to_sentence}"
        render_custom_403 :message => l(:redmine_cas_user_not_created, :user => session[:cas_user], :reason => user.errors.full_messages.to_sentence)
      end

      def render_custom_403(options = {})
        @project = nil
        render_custom_error({ :message => :notice_not_authorized, :status => 403 }.merge(options))
        false
      end

      def render_custom_error(arg)
        arg = { :message => arg } unless arg.is_a?(Hash)

        @message = arg[:message]
        @message = l(@message) if @message.is_a?(Symbol)
        @status = arg[:status] || 500

        respond_to do |format|
          format.html do
            render :template => 'redmine_cas/custom_error', :layout => use_layout, :status => @status
          end
          format.any { head @status }
        end
      end
    end
    module InstanceMethods
      def login

        return super if request.post? && RedmineCas.local_user_enabled?
        return super unless RedmineCas.enabled?
        return if RedmineCas.local_user_enabled?

        prev_url = request.referrer
        prev_url = home_url if prev_url.to_s.strip.empty?
        login_url = RedmineCas.get_cas_url + '/login?service=' + ERB::Util.url_encode(prev_url)
        redirect_to login_url
      end

      def logout
        return super unless RedmineCas.enabled?

        logout_user
        CASClient::Frameworks::Rails::Filter.logout(self, home_url)
      end

    end
  end
end
