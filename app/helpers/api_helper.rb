require 'net/http'
require 'uri'
require 'libxml'

module ApiHelper
  include LibXML
  
  JOBRO_BASE_URL = "#{API_CONFIG['jobro']['url']}?operation=searchRetrieve&version=1.2&query=jobro="
  ZEBRA_BASE_URL = API_CONFIG['zebra']['url']
  
  ### Helper functions ###
  private
  def articles_helper(issue_key)
    query_params = "/?operation=searchRetrieve&version=1.1&maximumRecords=200&x-pquery="
    query = "@attr 4=3 @attr stas-attset 1=3043 #{issue_key}"
    response = get_data(ZEBRA_BASE_URL+query_params,query)
    if response
      articles = parse_zebra_response(response) #result
      return articles
    else
      #render :status=>:not_found and return
      return
    end
  end
  
  private
  def next_key_helper(issn,issue_key)
    is_bound = false
    ### Key Markup ###
    # issn | ???? | volume_number | issue_number| ??? => (supplement || 000001)
    response = get_data(JOBRO_BASE_URL+issn)
    if response
      groups,issues = parse_jobro_response(response)
      
      if not issue_key
        return is_bound,groups[0]['issues'][groups[0]['issues'].size-1]['jobro_key']
      end
      
      if issues.has_key? issue_key
        issue = issues[issue_key]
        if issue['group'] == 0 and issue['issue'] == groups[issue['group']]['issues'].size-1 #groups.size-1
          # It is the newest issue!
          is_bound = true
          return is_bound,nil
        else
          if not issue['issue'] == groups[issue['group']]['issues'].size-1
            n_issue = groups[issue['group']]['issues'][issue['issue']+1]
            new_issue_key = n_issue['jobro_key']
            return is_bound,new_issue_key
          else
            n_issue = groups[issue['group']-1]['issues'][0]
            new_issue_key = n_issue['jobro_key']
            return is_bound,new_issue_key
          end
        end
      else
        # Key not found !
        return nil,nil
      end
    else
      return nil,nil
    end
  end
  
  private
  def prev_key_helper(issn,issue_key)
    is_bound = false
    ### Key Markup ###
    # issn | ???? | volume_number | issue_number| ??? => (supplement || 000001)
    response = get_data(JOBRO_BASE_URL+issn)
    if response
      groups,issues = parse_jobro_response(response)
      
      if not issue_key
        return is_bound,groups[groups.size-1]['issues'][0]['jobro_key']
      end
      
      if issues.has_key? issue_key
        issue = issues[issue_key]
        if issue['group'] == groups.size-1 and issue['issue'] == 0
          # It is the first issue! 
          is_bound = true
          return is_bound,nil
        else
          if not issue['issue'] == 0
            p_issue = groups[issue['group']]['issues'][issue['issue']-1]
            new_issue_key = p_issue['jobro_key']
            return is_bound,new_issue_key
          else
            p_issue = groups[issue['group']+1]['issues'][groups[issue['group']+1]['issues'].size-1]
            new_issue_key = p_issue['jobro_key']
            return is_bound,new_issue_key
          end
        end
      else
        # Key not found!
        return nil,nil
      end
    else
      return nil,nil
    end
  end
  ### Parse response ###
  private
  def parse_zebra_response(data)
    result = Hash.new
    result['records'] = Hash.new
    doc = XML::Document.string(data)
    number_of_records = doc.find_first('//zs:searchRetrieveResponse/zs:numberOfRecords').content
    result['number_of_records'] = number_of_records
    recordList = doc.find('//zs:searchRetrieveResponse/zs:records/zs:record')
    recordList.each do |record|
      record_position = record.find_first('./zs:recordPosition').content.to_i
      result['records'][record_position] = Hash.new
      # Member priority
      # 1.
      # 2. database
      # 3. aggregator
      member = nil
      memberList = record.find('./zs:recordData/xmlns:cluster/xmlns:member',['xmlns:http://schema.cvt.dk/articleDTU/2009'])
      if memberList.size == 1
        member = memberList[0]
      else
        member_priority = {'database'=>2,'aggregator'=>3}
        current_priority = 1000
        memberList.each do |m|
          puts "Unknown type: "+m['type'] if not member_priority.has_key? m['type'] #TODO: this should be removed at some point...
          current_priority = member_priority[m['type']] and member = m if member_priority.has_key? m['type'] and current_priority > member_priority[m['type']] 
        end
      end
      record_type = member.parent['category'] #find_first('./sf:art/sf:recordid/sf:rectypetxt',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_type'] = (record_type ? record_type : '')
      
      record_title = member.find_first('./sf:art/sf:article/sf:title',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_title'] = (record_title ? record_title.content : '')
      
      record_language = member.find_first('./sf:art/sf:article/sf:language',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_language'] = (record_language ? record_language.content : '')
      
      record_journal_issn = member.find_first('./sf:art/sf:journal/sf:issn',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_journal_issn'] = (record_journal_issn ? record_journal_issn.content : '')
      
      record_journal_eissn = member.find_first('./sf:art/sf:journal/sf:eissn',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_journal_eissn'] = (record_journal_eissn ? record_journal_eissn.content : '')
      
      record_journal_title = member.find_first('./sf:art/sf:journal/sf:title',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_journal_title'] = (record_journal_title ? record_journal_title.content : '')
      
      record_journal_vol = member.find_first('./sf:art/sf:journal/sf:vol',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_journal_vol'] = (record_journal_vol ? record_journal_vol.content : '')
      
      record_journal_issue = member.find_first('./sf:art/sf:journal/sf:issue',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_journal_issue'] = (record_journal_issue ? record_journal_issue.content : '')
      
      record_journal_year = member.find_first('./sf:art/sf:journal/sf:year',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_journal_year'] = (record_journal_year ? record_journal_year.content : '')
      
      record_page = member.find_first('./sf:art/sf:journal/sf:page',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      result['records'][record_position]['record_page'] = (record_page ? record_page.content : '')
      
      result['records'][record_position]['authors'] = Array.new
      authors = member.find('./sf:art/sf:author',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
      authors.each do |author|
        name = author.find_first('./sf:name',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
        role = author.find_first('./sf:role',['sf:http://schema.cvt.dk/art_oai_sf/2009'])
        result['records'][record_position]['authors'] << {'name'=>(name ? name.content : ''),'role'=>(role ? role.content : '')}
      end
    end # recordList
    return result
  end
  
  private
  def parse_jobro_response(data)
    groups = Array.new
    issues = Hash.new
    doc = XML::Document.string(data)
    groupList = doc.find('//response/records/record/group')
    groupList.each do |group|
      g = Hash.new
      name = group.find_first('./name').content
      g['name'] = name
      g['issues'] = Array.new
      issueList = group.find('./issue')
      issueList.each do |issue|
        issue_number = issue.content
        jobro_key = issue['search']
        issues[jobro_key] = Hash.new
        issues[jobro_key]['group'] = groups.size # This works because the current group haven't been added yet!
        issues[jobro_key]['issue'] = g['issues'].size # issue_number
        g['issues'] << {'issue_number'=>issue_number,'jobro_key'=>jobro_key}
      end
      groups << g
    end
    return groups,issues
  end
  
  ### HTTP Request ###
  private
  def get_data(url,query=nil)
    if url
      uri = URI.parse(url) if not query
      uri = URI.parse(url+URI.encode(query.strip)) if query
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      return response.body if response.code.to_i == 200
    end
    return
  end
end
