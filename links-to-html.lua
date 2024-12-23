-- links-to-html.lua
-- Converts paths that target x.md target x.html instead; add .html to anything with no extension -- should ignore 
function Link(el)
    el.target = string.gsub(el.target, "%.md", ".html")
    
    -- Check if the target has no extension and add .html
    if not string.match(el.target, "%.%w+$") then
        el.target = el.target .. ".html"
    end
    
    return el
end