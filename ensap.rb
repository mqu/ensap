#!/usr/bin/ruby

# Marc Quinton / janvier 2019 - client CLI sur le site de l'ENSAP ; version 0.1
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
		@url={
			:home  => 'https://ensap.gouv.fr/web/accueil',
			:login => 'https://ensap.gouv.fr/authentification',
			:remuneration => 'https://ensap.gouv.fr/prive/anneeremuneration/v1/',  # remuneration by year
			:download	=> 'https://ensap.gouv.fr/prive/telechargerdocumentremuneration/v1'
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
		JSON.parse(@client.get(@url[:remuneration]+year.to_s).body)['donnee']
	end

	# https://ensap.gouv.fr/prive/telechargerdocumentremuneration/v1?documentUuid=7bfef65e-XXXX-YYYY-aebb-001a4ae186a2
	def download id
		args={
			:documentUuid  => id
		}
		data=@client.get(@url[:download], args)
		return nil unless data.code=="200"
		return data.body
	end
	
	def download_by_year year, dir
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

client=Ensap.new '123456789012345', 'your-password'
if client.login
	puts "# connexion réussie"
  # pour les années de 2016 à l'année courante :
	(2016..Time.new.year).each do |y|
		client.download_by_year y, 'docs'
	end
end
