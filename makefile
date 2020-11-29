define PAGE_SETTINGS
colour size 29.7cm,21.0cm font \"Times-Roman,8\"
endef

GNUPLOT_FILE=burndown.gnuplot

OBJECTIVE=2021

GNUPLOT_SETTINGS:=
GNUPLOT_SETTINGS+=objective=2021
GNUPLOT_SETTINGS+=target_iso=\"2021-12-31T00:00\"
GNUPLOT_SETTINGS+=stretch_iso=\"2021-08-31T00:00\"
GNUPLOT_SETTINGS+=initial_iso=\"2020-10-27T00:00\"

PLOT=gnuplot $(foreach s,$(GNUPLOT_SETTINGS),-e "$(s)")

all: output/burndown.ps output/burndown.pdf showburndown

showburndown:
	$(PLOT) -p -e "set term qt size 1200,1024" $(GNUPLOT_FILE)

output:
	mkdir -p output

output/burndown.pdf: $(GNUPLOT_FILE) makefile | output
	$(PLOT) -e "set term postscript $(PAGE_SETTINGS)" $< > $@

output/burndown.ps: $(GNUPLOT_FILE) makefile | output
	$(PLOT) -e "set term pdf $(PAGE_SETTINGS)" $< > $@

clean:
	rm -rf output
