# Encoding: utf-8
require 'rubygems'
require 'mechanize'
require 'json'
require 'erb'
require_relative 'Colorizator'

include ERB::Util

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = 1

NUMERO_IMAGENS = ARGV[0]

if NUMERO_IMAGENS == "-h"
  puts "Uso ruby busca.rb Numero_de_Imagens Palavras Chave"
  exit
end

consulta = ""
ARGV.each_with_index do |parte, i|
    next if i == 0
    consulta += "#{parte} "
end

QUERY = consulta.strip!
ASPAS = '%22'
QUERY_COM_ASPAS = ASPAS + QUERY + ASPAS

puts QUERY_COM_ASPAS

IMAGENS_POR_PAGINA_NUMERO = 100
CAMPO_JSON_URL_IMAGEM = 'ou'
CAMPO_JSON_PAGINA_DA_IMAGEM = 'ru'
BIW = 1856
BIH = 471
CAMPO_REQUEST_GS_L = 'img.1.0.35i39k1.65297.65297.0.67043.4.4.0.0.0.0.208.208.2-1.1.0....0...1ac.1.64.img..3.1.207.0.JHPUAdTv4JY'

def process_page(page)
  puts 'Processando'
  doc = Nokogiri::HTML(page)
  array = doc.xpath('//div[@class="rg_di rg_bx rg_el ivg-i"]//div[@class="rg_meta"]/text()')
  array.each do |json_data|
    "Encontrei conteúdo"
    data = JSON.parse(json_data)
    print Colorizator.colorize("#{$image_number})", "black", "green")
    puts " #{data[CAMPO_JSON_URL_IMAGEM]}\n"
    if $result_image_urls["#{data[CAMPO_JSON_PAGINA_DA_IMAGEM]}"].nil?
      $result_image_urls["#{data[CAMPO_JSON_PAGINA_DA_IMAGEM]}"] = Hash.new
    end
    exit if $result_image_urls["#{data[CAMPO_JSON_PAGINA_DA_IMAGEM]}"]["#{data[CAMPO_JSON_URL_IMAGEM]}"] == 1
    $result_image_urls["#{data[CAMPO_JSON_PAGINA_DA_IMAGEM]}"]["#{data[CAMPO_JSON_URL_IMAGEM]}"] = 1
    output = File.open("coletas/#{QUERY}.csv", "a");
    output.print data[CAMPO_JSON_PAGINA_DA_IMAGEM];
    output.print ";"
    output.puts data[CAMPO_JSON_URL_IMAGEM];
    $image_number += 1
    exit if $image_number > NUMERO_IMAGENS.to_i
  end
  exit if array.length == 0
end

$result_image_urls = Hash.new

a = Mechanize.new { |agent|
  agent.user_agent = 'Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko'
}

first_request = 'https://www.google.com/search' +
                '?site=' +
                '&tbm=isch' +
                '&source=hp' +
                "&biw=#{BIW}" +
                "&bih=#{BIH}" +
                "&q=#{QUERY_COM_ASPAS}" +
                "&oq=#{QUERY_COM_ASPAS}" +
                "&gs_l=#{CAMPO_REQUEST_GS_L}"

puts first_request

a.get(first_request) do |page|
  $image_number = 1
  $page_number = 1
  $initial_image_page_number = 0
  loop do
    process_page(page.content)
    $page_number += 1
    $initial_image_page_number += IMAGENS_POR_PAGINA_NUMERO
    pagination_request = 'https://www.google.com/search' +
                         '?async=_id:rg_s,_pms:s' +
                         "&q=#{QUERY_COM_ASPAS}" +
                         '&tbm=isch' +
                         "&biw=#{BIW}" +
                         "&bih=#{BIH}" +
                         '&ijn=' + "#{$page_number - 1}" +
                         '&ei=JWu5WJSEFoTamwGmx6DQBA' +
                         '&start=' + $initial_image_page_number.to_s +
                         '&ved=0ahUKEwjUqquZtLrSAhUE7SYKHaYjCEoQuT0IGigB' +
                         '&vet=10ahUKEwjUqquZtLrSAhUE7SYKHaYjCEoQuT0IGigB.JWu5WJSEFoTamwGmx6DQBA.i'
    puts pagination_request
    page = a.get(pagination_request)
    #output = File.open("resultado.html", "w");output.puts page.to_s;
    #exit
    break if page.nil?
  end
end
