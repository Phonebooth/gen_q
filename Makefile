build_env_default=mob_qa
build_id_default=local
app=gen_q

# Jenkins vars
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
BUILD_ENV ?= $(build_env_default)
BUILD_ID ?= $(build_id_default)

build_name = $(app)-$(BRANCH)-$(BUILD_ID)
config_name = $(app)-$(BUILD_ENV).config
target = /opt/$(build_name)
arch := $(shell uname -s)

app_dir = test -d $(1) || mkdir $(1) && chown -R $(app):$(app) $(1)

all: subdirs

clean:
	rm -f c_src/*.o
	rm -f priv/${app}.so

subdirs: ensure-deps
	cd deps/pmod_transform && make && cd ../..
	@(./rebar compile)

ensure-deps:
	@(./rebar get-deps)

build: all
	@(tar cvfz $(build_name).tar.gz -X build.exclude *)

dirs:
	$(call app_dir,"/var/log/$(app)")
	$(call app_dir,"/var/db/$(app)")
	$(call app_dir,"/var/run/$(app)")
	$(call app_dir,$(target))

install: build dirs
	@(cp $(build_name).tar.gz /tmp)
	@(tar -xvz -C$(target) -f/tmp/$(build_name).tar.gz)
	@(chown -R $(app):$(app) $(target))
	@(rm -f /opt/$(app))
	@(ln -s $(target) /opt/$(app))
	@(chown -R $(app):$(app) /opt/$(app))
	@(rm -f /opt/$(app)/$(app).config)
	@(ln -s $(target)/$(config_name) /opt/$(app)/$(app).config)
	@(rm -f /opt/$(app)/.erlang.cookie)
	@(cp /home/jstimpson/.erlang.cookie /opt/$(app)/.erlang.cookie)

test: all
	@(./rebar eunit skip_deps=true)
