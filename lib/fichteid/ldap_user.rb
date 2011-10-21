require 'net/ldap'

module Fichteid
  module LdapUser
    AUTHORIZED_GROUP_ID = 10095
    BASEDN = 'ou=accounts,dc=fichteportfolio,dc=de'
    HOST = 'www.fichteportfolio.de'
    PORT = 636
    
    def self.connect &block
      Net::LDAP.open :encryption => :simple_tls, :base_dn => BASEDN, :host => HOST, :port => PORT, &block
    end
    
    def self.authenticated?(user, password)
      return false if user.empty? or password.empty?
      userdn = "uid=#{user},#{BASEDN}"
      
      auth_result = nil
      info = nil
      
      connect do |ldap|
        ldap.auth "uid=schneijo,#{BASEDN}", password
        auth_result = ldap.bind
        
        info = user_details ldap, user if auth_result == true
      end
      
      puts "LDAP result for authenticating #{user}: #{auth_result}, info=#{info.inspect}"
      auth_result ? info : auth_result
    end

    def self.user_details(ldap, username)
      f = Net::LDAP::Filter.eq("uid", username)
      entries = ldap.search(:base => BASEDN, :filter => f, :return_result => true)
      raise "#{entries.length} results found instead of 1" if entries.length != 1
      entry = entries.first
      
      {
        'username' => username,
        'name' => entry.cn.first,
        'group_ids' => entry['gidNumber'].join(',')
      }
    end
  end
end