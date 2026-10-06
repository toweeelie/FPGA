# 2026-10-05T15:17:54.297849500
import vitis

client = vitis.create_client()
client.set_workspace(path="project_6")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../../vivado/project_6/design_1_wrapper.xsa",os = "standalone",cpu = "ps7_cortexa9_0",domain_name = "standalone_ps7_cortexa9_0",compiler = "gcc")

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_ps7_cortexa9_0")

platform = client.get_component(name="platform")
status = platform.build()

status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

vitis.dispose()

