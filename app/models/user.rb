class User < ActiveRecord::Base
  # attr_accessible :title, :body
  def password=(password)
    self.password_salt = (0..7).map{('A'..'Z').to_a[rand(26)]}.join
    self.password_hash = Digest::SHA256.hexdigest(self.password_salt + password)
  end

  def password?(password)
    Digest::SHA256.hexdigest(self.password_salt + password) == self.password_hash
  end
end
