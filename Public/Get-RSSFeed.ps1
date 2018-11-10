function Get-RSSFeed {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)][System.Uri] $Url,
        [nullable[int]] $Count,
        [switch] $All
    )
    Begin {
        $ContentType = @"
    <?xml version="1.0" encoding="UTF-8"?><rss version="2.0"
        xmlns:content="http://purl.org/rss/1.0/modules/content/"
        xmlns:wfw="http://wellformedweb.org/CommentAPI/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
        xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
        >
"@
    }
    Process {
        $PageCount = 1
        while ($true) {
            #$BuildURL = $Url
            $BuildURL = "$($Url.Scheme)://$($Url.Authority)/feed/?paged=$PageCount"
            try {
                $Feed = [XML](Invoke-WebRequest -Uri $BuildURL -ContentType $ContentType ) # 'application/xml') # "charset=utf-8")

            } catch {
                #if ($)
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Warning $ErrorMessage
                break;
            }
            $RssData += $Feed.rss.channel.item | Select-Object * -ExcludeProperty InnerXML, InnerText, OuterXML

            if ($All) {

            } elseif ($Count) {
                if ($RssData.Count -gt $Count) {
                    break;
                }
            } else {
                break;
            }
            $PageCount++
        }
        if ($Count) {
            $RssData = $RssData | Select-Object -First $Count
        }

        $Blogs = @()
        foreach ($Blog in $RssData) {
            $Blogs += [PSCustomObject][ordered] @{
                PostID      = $Blog."post-id".InnerText
                Title       = $Blog.title
                Link        = $Blog.link
                PublishDate = $Blog.pubDate
                Creator     = $Blog.Creator.'#cdata-section'
                Categories  = $Blog.Category.'#cdata-section' -join ',' # actually for Wordpress it's a mix of Category/Tags
                isPermaLink = $Blog.Guid.isPermaLink
                LinkPerm    = $Blog.Guid.'#text'
                Description = $Blog.description.'#cdata-section'
                #Content           = ($Blog.encoded.'#cdata-section' -replace '<[^>]+>', '')
            }
        }
    }
    End {
        return $Blogs
    }
}