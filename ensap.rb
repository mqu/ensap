#!/usr/bin/ruby

# Marc Quinton / janvier 2019 - client CLI sur le site de l'ENSAP ; version 0.12
# URL du service : https://ensap.gouv.fr/
#
# cette application permet de recupérer vos fiches de paye numérisée sur le site de l'ENSAP
# - les fiches de paye sont disponibles depuis l'année 2016 jusqu'à l'année en cours
# - elles sont téléchargées localement dans le dossier "docs"
# - vous devez configurer le login et MDP ; le login est votre numéro de sécurité sociale en 15 chiffres
# - le fichier PDF ne sera pas téléchargé s'il est disponible localement. Pas de vérification d'intégrité sur le contenu
# 
# dependances : gem json, mechanize, (pp) 
#  commande d'installation : gem install pp json mechanize
# mots-clés ; keywords : ENSAP, PDF, API, script, CLI, github, download, téléchargement, fiche de paie, dématérialisation, pay sheet, fonction publique.
# links :
# - https://github.com/deep75/ENSAP-Mobile (android app)

require 'mechanize'
require 'pp'
require 'json'

class Ensap

	def initialize user, passwd	
		@user=user
		@passwd=passwd
		@client = Mechanize.new
		@cache={
			:years => nil
		}
		@url={
			:home  => 'https://ensap.gouv.fr/web/accueil',
			:login => 'https://ensap.gouv.fr/authentification',

			# habilitations / droits d'accès
			:acl	=> 'https://ensap.gouv.fr/prive/initialiserhabilitation/v1',
			
			# concerne les rémunérations
			# donne la liste des documents accessibles au téléchargement par année.
			:remuneration => 'https://ensap.gouv.fr/prive/anneeremuneration/v1/',  # remuneration by year
			:download	=> 'https://ensap.gouv.fr/prive/telechargerdocumentremuneration/v1',
			
			# quelles sont les années disponibles à la lecture, téléchargement
			:years  => 'https://ensap.gouv.fr/prive/listeanneeremuneration/v1'
			
		}
	end
	
	def login
		data = {
			'identifiant' => @user,
			'secret'	  => @passwd
        }
        res=@client.post(@url[:login], data)
        if res.body.match(/Authentification OK/)
			@client.get @url[:home]
			return true
        else
			return false
		end
	end

	# get some ACL and account status from portal
	#
	# {"lectureSeule"=>false,
	#  "listeService"=>
	#   {"compteindividuelretraite"=>true,
	#    "demandedepartretraite"=>true,
	#    "pensionne"=>false,
	#    "remuneration"=>true,
	#    "retraite"=>true,
	#    "simulation"=>false,
	#    "suividepartretraite"=>false}}
	def acl
		headers = { 'Content-Type' => 'application/json; charset=utf-8'}
		args={}
		JSON.parse(@client.post(@url[:acl], args, headers).body)
	end

	def years
		@cache[:years]=JSON.parse(@client.get(@url[:years]).body)['donnee'] unless @cache[:years]!=nil
		@cache[:years]
	end

	# return an array of hash :
	# {"documentUuid"=>"b0ba4820-XXXX-YYYY-bf90-06b560530509",
	# "libelle1"=>"Janvier 2018",
	# "libelle2"=>"2018_01_BP_janvier.pdf (PDF, 20 Ko)",
	# "nomDocument"=>"2018_01_BP_janvier.pdf",
	# "dateDocument"=>"2018-01-01T12:00:00.000+0100",
	# "annee"=>2018,
	# "icone"=>"document",
	# "libelleIcone"=>"Icône bulletin de paye"},
	def remuneration_by_year year
		puts "remuneration_by_year(#{year})"
		if year==:all
			list=[]
			self.years.each do |y|
				list.concat(self.remuneration_by_year(y))
			end
			return list.sort_by{ |e| e['dateDocument']}
		else
			JSON.parse(@client.get(@url[:remuneration]+year.to_s).body)['donnee']
		end
	end
	alias ls remuneration_by_year


	# https://ensap.gouv.fr/prive/telechargerdocumentremuneration/v1?documentUuid=XYZ-XXX-123
	def download id
		args={
			:documentUuid  => id
		}
		data=@client.get(@url[:download], args)
		return nil unless data.code=="200"
		return data.body
	end
	
	def download_by_year year, dir
		puts "download_by_year(#{dir})"
		if year==:all
			self.years.each do |y|
				self.download_by_year y, dir
			end
		else
			Dir.mkdir dir unless Dir.exist? dir
			
			self.remuneration_by_year(year).each do |_doc|
				file='docs/'+_doc['nomDocument']
				unless File.exist? file
					puts "# downloading " + _doc['nomDocument']
					data=self.download _doc['documentUuid']
					IO.write(file, data) unless data==nil
				end
			end
		end	
	end
	
	def dl_all dir='docs/'
		self.years.each do |y|
			self.dl y, dir
		end
	end
	
end

if ARGV.size>=2
	client=Ensap.new ARGV[0], ARGV[1]
else
	# you can modify user and password here.
	client=Ensap.new '123456789012345', 'your-password'
end

if ARGV.size==3
	cmd=ARGV[2]
else
	cmd=:ls
end

docs='./docs'

if client.login
	puts "# connexion réussie"
	
	case cmd.to_sym

		when :test
			pp client.years

		when :acl
			pp client.acl

		when :ls
			year=:all if ARGV.size==3
			year=ARGV[3].to_sym if ARGV.size==4
			pp client.ls year

		# dowload all documents to localdir
		when :dl|:download
			# pour les années de 2016 à l'année courante :
			client.dl :all, docs

		# download current year
		when :dl_current
			# pour les années de 2016 à l'année courante :
			client.dl Time.new.year, docs
	end
else
	puts "# connexion error"
end
