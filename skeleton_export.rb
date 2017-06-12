require 'yaml'
require 'base64'
require "openssl"

################################################################################
# This is needed because `OpenSSL::PKCS5.pbkdf2_hmac` doesn't work on mac.
# https://github.com/cyx/armor
# MIT license

module Armor
  Digest = RUBY_VERSION >= "2.1.0" ? OpenSSL::Digest : OpenSSL::Digest::Digest

  # Syntactic sugar for the underlying mathematical definition of PBKDF2.
  #
  # This function does not allow passing in of a dkLen (in other words
  # does not allow truncation of the final derived key).
  #
  # Returns: Binary representation of the derived key (DK).
  #
  # The default value for iter is set to 5000, and it can be
  # configured via `ENV['ARMOR_ITER']`.
  #
  # The default value for hash is "sha512", and it can also be
  # configured via `ENV['ARMOR_HASH']`.
  def self.digest(password, salt)
    iter = ENV["ARMOR_ITER"] || 5000
    hash = ENV["ARMOR_HASH"] || "sha512"

    digest = Digest.new(hash)
    length = digest.digest_length

    hex(pbkdf2(digest, password, salt, Integer(iter), length))
  end

  def self.randomize(digest, password, seed)
    OpenSSL::HMAC.digest(digest, password, seed)
  end

  # Binary to hex convenience method.
  def self.hex(str)
    str.unpack("H*").first
  end

  # The PBKDF2 key derivation function has five input parameters:
  #
  #     DK = PBKDF2(PRF, Password, Salt, c, dkLen)
  #
  # where:
  #
  # - PRF is a pseudorandom function of two parameters
  # - Password is the master password from which a derived key is generated
  # - Salt is a cryptographic salt
  # - c is the number of iterations desired
  # - dkLen is the desired length of the derived key
  #
  #   DK is the generated derived key.
  #
  def self.pbkdf2(digest, password, salt, c, dk_len)
    blocks_needed = (dk_len.to_f / digest.size).ceil

    result = ""

    # main block-calculating loop:
    1.upto(blocks_needed) do |n|
      result << concatenate(digest, password, salt, c, n)
    end

    # truncate to desired length:
    result.slice(0, dk_len)
  end

  # The function F is the xor (^) of c iterations of chained PRFs.
  # The first iteration of PRF uses Password as the PRF key and Salt
  # concatenated to i encoded as a big-endian 32-bit integer.
  #
  # Note that i is a 1-based index. Subsequent iterations of PRF use
  # Password as the PRF key and the output of the previous PRF
  # computation as the salt:
  #
  # Definition:
  #
  #     F(Password, Salt, Iterations, i) = U1 ^ U2 ^ ... ^ Uc
  #
  def self.concatenate(digest, password, salt, iterations, i)

    # U1 -> password, salt and 1 encoded as big-endian 32-bit integer.
    u = randomize(digest, password, salt + [i].pack("N"))

    ret = u

    # U2 through Uc:
    2.upto(iterations) do

      # calculate Un
      u = randomize(digest, password, u)

      # xor it with the previous results
      ret = xor(ret, u)
    end

    ret
  end

  # Time-attack safe comparison operator.
  #
  # @see http://bit.ly/WHHHz1
  def self.compare(a, b)
    return false unless a.length == b.length

    cmp = b.bytes.to_a
    result = 0

    a.bytes.each_with_index do |char, index|
      result |= char ^ cmp[index]
    end

    return result == 0
  end

  def self.xor(a, b)
    result = "".encode("ASCII-8BIT")

    b_bytes = b.bytes.to_a

    a.bytes.each_with_index do |c, i|
      result << (c ^ b_bytes[i])
    end

    result
  end

  def self.sha256
    return Digest.new('sha256')
  end
end

################################################################################

def load_groups
  groups = {}
  Dir["group_*.yaml"].each do |file|
    yaml = YAML.load_file(file)
    name = yaml["name"]
    id = yaml["id"]
    groups[id] = name
  end
  groups
end

def load_key
  STDERR.puts 'Master password: '
  password = gets.rstrip
  password_yaml = YAML.load_file('password.yaml')
  salt = Base64.decode64(password_yaml["PBKDF2_salt"])
  rounds = password_yaml["PBKDF2_rounds"]
  key = Armor.pbkdf2(Armor.sha256, password, salt, rounds, 32)
  return key
end

def decipher(value, key)
  begin
    cipher = OpenSSL::Cipher::AES256.new(:ECB).decrypt
    cipher.key = key
    return cipher.update(value) + cipher.final
  rescue
    return "ERROR DECIPHERING"
  end
end

# Takes base64-text or nil, returns the deciphered text or a nil.
def decipher_base64(value_base64, key)
  if blank(value_base64)
    return nil
  else
    cipher_text = Base64.decode64(value_base64)
    return decipher(cipher_text, key)
  end
end

# Makes csv out of an array of strings. Nils converted into empty strings.
def csv(array)
  nilfix = array.map { |s| blank(s) ? "" : s }
  quoted = nilfix.map { |s| '"' + s.gsub('"',"'") + '"' }
  return quoted.join(',')
end

def blank(string)
  return string.nil? || string.empty?
end

def process_item(yaml, key, groups)
  name = yaml["name"]
  group_id = yaml["group_id"]
  group = groups[group_id]
  extras = []
  notes = decipher_base64(yaml["notes"], key)
  unless blank(notes)
    extras.push(notes)
  end
  username = nil
  password = nil
  fields = yaml["fields"]
  fields.each do |field|
    field_name = field["name"]
    field_value = decipher_base64(field["value"], key)
    unless blank(field_value)
      if field_name == "Login"
        username = field_value
      elsif field_name == "Password"
        password = field_value
      else
        extras.push(field_name + ": " + field_value)
      end
    end
  end

  # Format it into lastpass format.
  url = nil
  type = nil
  hostname = nil
  extra = extras.join('; ')
  return [url,type,username,password,hostname,extra,name,group]
end

def process_items(key, groups)
  puts 'url,type,username,password,hostname,extra,name,grouping'
  Dir["item_*.yaml"].each do |file|
    yaml = YAML.load_file(file)
    item = process_item(yaml, key, groups)
    puts csv(item)
  end
end

STDERR.puts 'Skeleton Key password exporter. Run this in the same folder as all your YAML files.'
STDERR.puts 'Windows usage: ruby skeleton_export.rb | clip'
STDERR.puts 'Mac usage: ruby skeleton_export.rb | pbcopy'
STDERR.puts 'Enter your master password when asked, then this will put all your data in the clipboard.'
STDERR.puts 'Then you can paste it all into eg LastPass.'

groups = load_groups
key = load_key
process_items(key, groups)

STDERR.puts 'Done - now you can paste into eg the LastPass import interface: More Options > Advanced > Import > Generic CSV file'
