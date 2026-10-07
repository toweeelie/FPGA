# 2026-10-07T13:42:35.715744300
import vitis

client = vitis.create_client()
client.set_workspace(path="project_7")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../../vivado/project_7/design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="app_component")
status = comp.import_files(from_loc="", files=["C:\Users\NovokhatkoTaras\Work\FPGA\homework_4\vitis\project_6\app_component\src\main.c"], is_skip_copy_sources = False)

status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

