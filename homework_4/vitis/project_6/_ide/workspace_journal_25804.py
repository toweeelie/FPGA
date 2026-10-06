# 2026-10-05T18:18:21.028067400
import vitis

client = vitis.create_client()
client.set_workspace(path="project_6")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

vitis.dispose()

