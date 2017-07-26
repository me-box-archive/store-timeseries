## Time series datatore

Store JSON or JPEG images.

### JSON API

#### Read latest entry
    URL: /<id>/ts/latest/
    Method: GET
    Parameters: replace <id> with an identifier
    Notes: return the latest entry
    
#### Read last number of entries
    
    URL: /<id>/ts/last/<n>/
    Method: GET
    Parameters: replace <id> with an identifier, replace <n> with the number of entries
    Notes: return the number of entries requested
    
    
#### Read all entries since a time
    
    URL: /<id>/ts/since/<from>/
    Method: GET
    Parameters: replace <id> with an identifier, replace <from> with epoch seconds
    Notes: return the number of entries from time provided
    
#### Read all entries in a time range
    
    URL: /<id>/ts/range/<from>/<to>/
    Method: GET
    Parameters: replace <id> with an identifier, replace <from> and <to> with epoch seconds
    Notes: return the number of entries in time range provided
    
#### Read last number of entries then restrict since a time
    
    URL: /<id>/ts/last/<n>/since/<from>/
    Method: GET
    Parameters: replace <id> with an identifier, replace <n> with the number of entries, replace <from> with epoch seconds
    Notes: return the last number of entries and then filter result on time
    
#### Read last number of entries then restrict in a time range
    
    URL: /<id>/ts/last/<n>/range/<from>/<to>/
    Method: GET
    Parameters: replace <id> with an identifier, replace <n> with the number of entries, replace <from> and <to> with epoch seconds
    Notes: return the last number of entries and then filter result on time
    
#### Write entry
    URL: /<id>/ts/
    Method: POST
    Parameters: JSON body of data, replace <id> with an identifier
    Notes: add data to time series with given identifier

### Image API

Allows JPEGs to be stored and retrieved based on a UUID. To retrieve an image first query the time series identifier to get a list of entries and then retrieve a specific image using a specific UUID. TODO: Store image Exif data with the UUID and allow searching on the meta-data

#### Read image

    URL: /<uuid>/image/
    Method: GET
    Parameters: replace <uuid> with image UUID
    Notes: return the image stored with UUID
    
#### Write image

    URL: /<id>/image/
    Method: POST
    Parameters: body of image data, replace <id> with an identifier
    Notes: add image to time series with given identifier  