require 'net/http'
require 'net/https'

class AuthSourceCas < AuthSource
  NETWORK_EXCEPTIONS = [
    Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ECONNRESET,
    Errno::EHOSTDOWN, Errno::EHOSTUNREACH,
    SocketError
  ]

  def authenticate(login, password)
    return nil if login.blank? || password.blank?

    # request a ticket granting ticket
    tgt_uri = "#{RedmineCas.get_cas_url}/v1/tickets"
    tgt_form_data = { 'username' => login, 'password' => password }
    tgt = RedmineCas.api_request(tgt_uri, tgt_form_data)

    if tgt.code == '201'
      # get ticket granting ticket from response
      forms = Nokogiri::HTML(tgt.body).xpath('//form').to_s
      sub = forms.index('https')
      sub2 = forms.index('method')
      tgticket = forms.to_s[sub, sub2 - sub - 2]
      # request a service ticket
      st_uri = tgticket
      service = RedmineCas.get_redmine_url
      st_form_data = { 'service' => service }
      serviceTicket = RedmineCas.api_request(st_uri, st_form_data)

      # successfully got ticket granting ticket?
      if serviceTicket.code == '200'
        ticket = serviceTicket.body
        pt = CASClient::ServiceTicket.new(ticket, service)
        #Validate Service Ticket --> GET /p3/serviceValidate
        validationResponse = CASClient::Frameworks::Rails::Filter.client.validate_service_ticket(pt)

        # check if validation was successful
        if validationResponse.success
          userAttributes = validationResponse.extra_attributes

          mapping=RedmineCas.get_attribute_mapping
          user_mail = userAttributes[mapping["mail"]]
          user_surname = userAttributes[mapping["lastname"]]
          user_givenName = userAttributes[mapping["firstname"]]
          user_groups = userAttributes[mapping["allgroups"]]

          user = RedmineCas::UserManager.create_or_update_user(login, user_givenName, user_surname, user_mail, user_groups)
          user.last_login_on = Time.now
          user.save!

          # return new user information
          retVal =
            {
              :id => user.id,
              :firstname => user_givenName,
              :lastname => user_surname,
              :mail => user_mail,
              :auth_source_id => self.id,
              :admin => user.admin
            }
          return retVal
        else
          logger.error('Service ticket validation failure')
        end
      else
        logger.error('No Service ticket granted')
      end
    else
      logger.error('Authentication data not accepted')
    end
    return nil
  rescue *NETWORK_EXCEPTIONS => e
    raise AuthSourceException.new(e.message)
  end

  def auth_method_name
    'CAS'
  end

end
