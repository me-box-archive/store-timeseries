## Time series datatore

JSON data store for time series and key/value data.

### Key/Value API

#### Read entry

    URL: /<key>/kv/
    Method: GET
    Parameters: replace <key> with document key
    Notes: return the data stored with key
    
#### Write entry

    URL: /<key>/kv/
    Method: POST
    Parameters: JSON body of data
    Notes: add data using key and overwrite any existing data
    
### Time series database API

#### Read latest entry
    URL: /ts/latest
    Method: GET
    Parameters: 
    Notes: return the latest entry
    
#### Read last entries
    
    URL: /ts/last/<n>
    Method: GET
    Parameters: replace <n> with the number of entries
    Notes: return the number of entries requested
    
    
#### Read last entries since time (unix epoch)
    
    URL: /ts/since/<t>
    Method: GET
    Parameters: replace <t> with epoch seconds
    Notes: return the number of entries requested since time provided
    
#### Read last entries since time (unix epoch)
    
    URL: /ts/since/<t>
    Method: GET
    Parameters: replace <t> with epoch seconds
    Notes: return the number of entries requested since time provided
    