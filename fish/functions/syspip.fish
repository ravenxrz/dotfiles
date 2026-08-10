function syspip -d "Use pip without requiring virtualenv"
    PIP_REQUIRE_VIRTUALENV="" pip $argv
end
