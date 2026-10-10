    # LED
    set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led_tri_o[0]}]
    set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led_tri_o[1]}]
    set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led_tri_o[2]}]
    set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led_tri_o[3]}]
    # Buttons
    set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {btn_tri_i[0]}]
    set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {btn_tri_i[1]}]
    set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports {btn_tri_i[2]}]
    # Switch
    set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {sw_tri_i[0]}]