---
title: Link Test Page
date: 2024-12-01
subtitle: "Subtitle. Note that date will be overridden by command line-set variable"
---

# Start of body - Links

Regular:
- [[WikiLink]] --> [Wikilink](Wikilink)
- `[[WikiLink]]` --> `[Wikilink](Wikilink)`
- Target `./Wikilink.html`

With space:
- [[Wiki Link]] --> [Wiki Link](Wiki Link)
- `[[Wiki Link]]` --> `[Wiki Link](Wiki Link)`
- Target `./Wiki%20Link.html`

With alias:
- [[Alias|WikiLink to Alias]] --> [WikiLink to Alias](Alias)
- `[[Alias|WikiLink to Alias]]` --> `[WikiLink to Alias](Alias)`
- Target `./Alias.html`

With subfolder:
- [[Subfolder/Subnote|Subnote]] --> [Subnote](Subfolder/Subnote)
- `[[Subfolder/Subnote|Subnote]]` --> `[Subnote](Subfolder/Subnote)`
- Target `./Subfolder/Subnote.html`

With anchor:
- [[WikiLink#anchor]] --> [WikiLink#anchor](WikiLink#anchor)
- `[[WikiLink#anchor]]` --> `[WikiLink#anchor](WikiLink#anchor)`
- Target `./WikiLink.html#anchor`
- Fixed with new version of `links-to-html.lua`
	- **Note** Currently doesn't work. Would need to either:
		a) add .md to destination, and replace `.md#` with `.html#` - `[WikiLink#anchor](WikiLink.md#anchor)` should work ([WikiLink#anchor](WikiLink.md#anchor))
		b) strip .html from all urls

There are some other formats that are automatically handled by Pandoc
- <https://google.com> <sam@green.eggs.ham> should resolve to the mentioned URL and mailto: address when wrapped in `<>`:
	```
	<https://google.com>
	<sam@green.eggs.ham>
	```
- `[MarkdownLink](MarkdownLink "Title")` will give a title attribute to the generated link; haven't found equivalent for WikiLinks yet: [MarkdownLink](MarkdownLink "Title")
- `[Email](sam.a.g.carr@gmail.com)` doesn't create a mailto link automatically - needs mailto in MD link: `[Email](mailto:sam.a.g.carr@gmail.com)` [Email](mailto:sam.a.g.carr@gmail.com)


# Images

This is an embedded image using a wikilink: ![[image.png]]

This is an image with alt text: ![[image.png|alt=Alternate text]]

# Other
`![[Postcards]]` should embed the whole postcards page below:
- ![[Postcards]]

End of file - everything below is generated