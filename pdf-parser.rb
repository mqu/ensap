#!/usr/bin/ruby

require 'pp'
require 'pdf/reader'

# Return information about pay-sheet extracted from PDF.
# {:meta=>
#   {:title=>"PAY18E",
#    :creator=>"OpenText Exstream Version 9.5.304 64-bit",
#    :date=>"12/14/2018 20:41:59",
#    :author=>"Registered to: DGCP",
#    :pages=>1,
#    :filename=>"docs/2018_12_BP_decembre.pdf",
#    :version=>"V2.0 - 26062018"},
#  :pay=>
#   {:month=>"decembre",
#    :year=>"2018",
#    :net=>XXXX,
#    :brut=>XXXX,
#    :employeur=>XXXX},
#  :tax=>{:year=>XXXX, :month=>XXXX.X},
#  :extra=>
#   {:account=>"FR76 XXXXXXX",
#    :heures=>"+.DE.120.H",
#    :date_paiement=>"18 decembre 2018 ",
#    :secu=>"1.XXXX",
#    :secu_cle=>"58",
#    :grade=>"XXXX",
#    :indice=>123,
#    :indice_nbi=>75}}

class PaySheetPdfParser
	def self.parse file
		pdf = PDF::Reader.new(file)
		txt=pdf.pages[0].text.split("\n")

		infos={
			:meta =>{
				:title => pdf.info[:Title].strip,
				:creator => pdf.info[:Creator].strip,
				:date => pdf.info[:CreationDate].strip,
				:author => pdf.info[:Author].strip,
				:pages  => pdf.pages.size,
				:filename => file
			},
			:pay => {},
			:tax => {},
			:extra => {},
		}
		txt.each do |_l|
			if _l.match(/NET À PAYER\s+(\d[ \d,]+\d)\s+€/)
				infos[:pay][:net]=$1.tr(' ','').tr(',','.').to_f
			end
			if _l.match(/MOIS DE\s+(.+)$/)
				date=$1.downcase
				infos[:pay][:month]=date.split[0]
				infos[:pay][:year]=date.split[1]
			end
		end
		
		pdf.pages[0].raw_content.split("\n").each do |_l| 
			# version de la fiche de paye
			# ... (PAY18E) Tj 0.000 -1.000 1.000 0.000 4832 1236 Tm ( - V1.4 - 25102016) ...
			if _l.match(/PAY18E.*\( - (.*)\) /)
				infos[:meta][:version]=$1
			end
			
			# traitement brut
			if _l.match(/\/F243 75.0000 Tf 321[24] 6011 Td \(\s*(.*)\) Tj/)
				infos[:pay][:brut]=$1.tr(',','.').to_f
			end
			
			# cout employeur
			if _l.match(/\/F243 83.3333 Tf 1836 1894 Td \(\s*(.*)\) Tj/)
				infos[:pay][:employeur]=$1.tr(',','.').to_f
			end

			# montant imposable de l'année
			if _l.match(/\/F243 83.3333 Tf 183 1188 Td \(\s*(.*)\) Tj/)
				infos[:tax][:year]=$1.tr(' ','').to_f
			end

			# montant imposable de du mois
			if _l.match(/\/F243 83.3333 Tf 989 1188 Td \(\s*(.*)\) Tj/)
				infos[:tax][:month]=$1.tr(' ','').to_f
			end

			# indice
			if _l.match(/\/F243 83.3333 Tf 3462 6252 Td \(\s*(.*)\) Tj/)
				infos[:extra][:indice]=$1.to_i
			end
			# indice NBI
			if _l.match(/\/F243 83.3333 Tf 3860 6252 Td \(\s*(.*)\) Tj/)
				infos[:extra][:indice_nbi]=$1.sub('NBI ','').to_i
			end

			# grade
			if _l.match(/\/F243 83.3333 Tf 1784 6252 Td \(\s*(.*)\) Tj/)
				infos[:extra][:grade]=$1
			end
			# num secu
			if _l.match(/\/F243 83.3333 Tf 370 6252 Td \(\s*(.*)\) Tj/)
				infos[:extra][:secu]=$1.tr(' ','.')
			end
			# num secu/clé
			if _l.match(/\/F243 83.3333 Tf 1386 6252 Td \(\s*(.*)\) Tj/)
				infos[:extra][:secu_cle]=$1.tr(' ','.')
			end
			# temps activité (heures)
			if _l.match(/\/F243 83.3333 Tf 4293 6885 Td \(\s*(.*)\) Tj/)
				infos[:extra][:heures]=$1.tr(' ','.')
			end
		
			# date mise en paiement
			if _l.match(/\/F243 83.3333 Tf 484 586 Td \(\s*(.*)\) Tj/)
				infos[:extra][:date_paiement]=$1.gsub(/  */,' ').downcase
			end
			# compte
			if _l.match(/\/F243 83.3333 Tf 89 312 Td \(\s*(.*?)\) Tj\s0 -95 Td \(\s+(.*)\)/)
				infos[:extra][:account]=$1+'-'+$2
			end

		end
		return infos
	end
	
	def self.parse_raw file
		pdf = PDF::Reader.new(file)
		pdf.pages[0].raw_content
	end
end

doc="docs/2017_12_BP_decembre.pdf"
test=:pdf_parser
test=:parse
# test=:origami

case test

when :origami
	require 'origami'
	pdf = Origami::PDF.read doc
	pp pdf.pages.each do |p|
		pp p.class
	end

when :pdf_parser
	pp PaySheetPdfParser.parse doc
	
when :parse
	Dir.glob('docs/*BP*.pdf').sort.each do |f|
		pp PaySheetPdfParser.parse f
	end

when :parse_raw
	Dir.glob('docs/*BP*.pdf').sort.each do |f|
		IO.write(f + '.raw', PaySheetPdfParser.parse_raw(f).to_s)
	end
end
