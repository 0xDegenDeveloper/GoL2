import base64
def extract_and_concatenate_debug_output(text):
    lines = text.split('\n')
    extracted_chars = []

    for line in lines:
        if '[DEBUG]' in line:
            parts = line.split()
            if len(parts) > 1:
                extracted_chars.append(parts[1])

    concatenated_string = ''.join(extracted_chars)
    return concatenated_string

def decode_base64(encoded_string):
    try:
        decoded_bytes = base64.b64decode(encoded_string)
        return decoded_bytes.decode('ascii')
    except Exception as e:
        return f"Error |{encoded_string}|"

# Example usage
# example_text = """
# [DEBUG] data:application/json,{         (raw: 0x646174613a6170706c69636174696f6e2f6a736f6e2c7b

# [DEBUG] "name":"GoL2 #                  (raw: 0x226e616d65223a22476f4c322023

# [DEBUG] 1234                            (raw: 0x31323334

# [DEBUG] ","description":"Snapshot       (raw: 0x222c226465736372697074696f6e223a22536e617073686f74

# [DEBUG]  of GoL2 Game at generation     (raw: 0x206f6620476f4c322047616d652061742067656e65726174696f6e20

# [DEBUG] 1234                            (raw: 0x31323334

# [DEBUG] ","image":"                     (raw: 0x222c22696d616765223a22

# [DEBUG] data:image/svg+xml,             (raw: 0x646174613a696d6167652f7376672b786d6c2c

# [DEBUG] data:image/svg+xml,             (raw: 0x646174613a696d6167652f7376672b786d6c2c

# [DEBUG] <svg xmlns="                    (raw: 0x3c73766720786d6c6e733d22

# [DEBUG] http://www.w3.org/2000/svg"     (raw: 0x687474703a2f2f7777772e77332e6f72672f323030302f73766722

# [DEBUG]  width="910" height="910"       (raw: 0x2077696474683d2239313022206865696768743d2239313022

# [DEBUG]  viewBox="0 0 910 910">         (raw: 0x2076696577426f783d223020302039313020393130223e

# [DEBUG] <g transform="translate(5 5)">  (raw: 0x3c67207472616e73666f726d3d227472616e736c6174652835203529223e

# [DEBUG] <rect width="900" height="900"  (raw: 0x3c726563742077696474683d2239303022206865696768743d2239303022

# [DEBUG]  fill="#1e222b"/>               (raw: 0x2066696c6c3d2223316532323262222f3e

# [DEBUG] <g stroke="#5e6266"             (raw: 0x3c67207374726f6b653d222335653632363622

# [DEBUG]  stroke-width="1">              (raw: 0x207374726f6b652d77696474683d2231223e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 120                             (raw: 0x313230

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 120                             (raw: 0x313230

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 120                             (raw: 0x313230

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 120                             (raw: 0x313230

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 180                             (raw: 0x313830

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 180                             (raw: 0x313830

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 180                             (raw: 0x313830

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 180                             (raw: 0x313830

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 240                             (raw: 0x323430

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 240                             (raw: 0x323430

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 240                             (raw: 0x323430

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 240                             (raw: 0x323430

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 300                             (raw: 0x333030

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 300                             (raw: 0x333030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 300                             (raw: 0x333030

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 300                             (raw: 0x333030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 360                             (raw: 0x333630

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 360                             (raw: 0x333630

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 360                             (raw: 0x333630

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 360                             (raw: 0x333630

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 420                             (raw: 0x343230

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 420                             (raw: 0x343230

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 420                             (raw: 0x343230

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 420                             (raw: 0x343230

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 540                             (raw: 0x353430

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 540                             (raw: 0x353430

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 540                             (raw: 0x353430

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 540                             (raw: 0x353430

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 600                             (raw: 0x363030

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 600                             (raw: 0x363030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 600                             (raw: 0x363030

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 600                             (raw: 0x363030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 660                             (raw: 0x363630

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 660                             (raw: 0x363630

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 660                             (raw: 0x363630

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 660                             (raw: 0x363630

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 720                             (raw: 0x373230

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 720                             (raw: 0x373230

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 720                             (raw: 0x373230

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 720                             (raw: 0x373230

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 780                             (raw: 0x373830

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 780                             (raw: 0x373830

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 780                             (raw: 0x373830

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 780                             (raw: 0x373830

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 840                             (raw: 0x383430

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 840                             (raw: 0x383430

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] <line x1="                      (raw: 0x3c6c696e652078313d22

# [DEBUG] 840                             (raw: 0x383430

# [DEBUG] " y1="                          (raw: 0x222079313d22

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] " x2="                          (raw: 0x222078323d22

# [DEBUG] 840                             (raw: 0x383430

# [DEBUG] " y2="                          (raw: 0x222079323d22

# [DEBUG] 900                             (raw: 0x393030

# [DEBUG] "/>                             (raw: 0x222f3e

# [DEBUG] </g><g fill="#dff17b"           (raw: 0x3c2f673e3c672066696c6c3d222364666631376222

# [DEBUG]  stroke="#dff17b"               (raw: 0x207374726f6b653d222364666631376222

# [DEBUG]  stroke-width="0.5">            (raw: 0x207374726f6b652d77696474683d22302e35223e

# [DEBUG] <rect width="                   (raw: 0x3c726563742077696474683d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " height="                      (raw: 0x22206865696768743d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " transform="translate(         (raw: 0x22207472616e73666f726d3d227472616e736c61746528

# [DEBUG] 540                             (raw: 0x353430

# [DEBUG]                                 (raw: 0x20

# [DEBUG] 360                             (raw: 0x333630

# [DEBUG] )"/>                            (raw: 0x29222f3e

# [DEBUG] <rect width="                   (raw: 0x3c726563742077696474683d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " height="                      (raw: 0x22206865696768743d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " transform="translate(         (raw: 0x22207472616e73666f726d3d227472616e736c61746528

# [DEBUG] 660                             (raw: 0x363630

# [DEBUG]                                 (raw: 0x20

# [DEBUG] 420                             (raw: 0x343230

# [DEBUG] )"/>                            (raw: 0x29222f3e

# [DEBUG] <rect width="                   (raw: 0x3c726563742077696474683d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " height="                      (raw: 0x22206865696768743d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " transform="translate(         (raw: 0x22207472616e73666f726d3d227472616e736c61746528

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG]                                 (raw: 0x20

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] )"/>                            (raw: 0x29222f3e

# [DEBUG] <rect width="                   (raw: 0x3c726563742077696474683d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " height="                      (raw: 0x22206865696768743d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " transform="translate(         (raw: 0x22207472616e73666f726d3d227472616e736c61746528

# [DEBUG] 540                             (raw: 0x353430

# [DEBUG]                                 (raw: 0x20

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] )"/>                            (raw: 0x29222f3e

# [DEBUG] <rect width="                   (raw: 0x3c726563742077696474683d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " height="                      (raw: 0x22206865696768743d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " transform="translate(         (raw: 0x22207472616e73666f726d3d227472616e736c61746528

# [DEBUG] 720                             (raw: 0x373230

# [DEBUG]                                 (raw: 0x20

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] )"/>                            (raw: 0x29222f3e

# [DEBUG] <rect width="                   (raw: 0x3c726563742077696474683d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " height="                      (raw: 0x22206865696768743d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " transform="translate(         (raw: 0x22207472616e73666f726d3d227472616e736c61746528

# [DEBUG] 780                             (raw: 0x373830

# [DEBUG]                                 (raw: 0x20

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] )"/>                            (raw: 0x29222f3e

# [DEBUG] <rect width="                   (raw: 0x3c726563742077696474683d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " height="                      (raw: 0x22206865696768743d22

# [DEBUG] 60                              (raw: 0x3630

# [DEBUG] " transform="translate(         (raw: 0x22207472616e73666f726d3d227472616e736c61746528

# [DEBUG] 840                             (raw: 0x383430

# [DEBUG]                                 (raw: 0x20

# [DEBUG] 480                             (raw: 0x343830

# [DEBUG] )"/>                            (raw: 0x29222f3e

# [DEBUG] </g><rect width="900"           (raw: 0x3c2f673e3c726563742077696474683d2239303022

# [DEBUG]  height="900"                   (raw: 0x206865696768743d2239303022

# [DEBUG]  fill="none"                    (raw: 0x2066696c6c3d226e6f6e6522

# [DEBUG]  stroke="#0a0c10"               (raw: 0x207374726f6b653d222330613063313022

# [DEBUG]  stroke-width="5"/>             (raw: 0x207374726f6b652d77696474683d2235222f3e

# [DEBUG] </g></svg>                      (raw: 0x3c2f673e3c2f7376673e

# [DEBUG] ","external_url":               (raw: 0x222c2265787465726e616c5f75726c223a

# [DEBUG] "https://gol2.io",              (raw: 0x2268747470733a2f2f676f6c322e696f222c

# [DEBUG] "attributes":                   (raw: 0x2261747472696275746573223a

# [DEBUG] [                               (raw: 0x5b

# [DEBUG] {"trait_type":"Generation",     (raw: 0x7b2274726169745f74797065223a2247656e65726174696f6e222c

# [DEBUG] "value":"                       (raw: 0x2276616c7565223a22

# [DEBUG] 115                             (raw: 0x313135

# [DEBUG] 4                               (raw: 0x34

# [DEBUG] 2                               (raw: 0x32

# [DEBUG] 2                               (raw: 0x32

# [DEBUG] 4                               (raw: 0x34

# [DEBUG] 2                               (raw: 0x32

# [DEBUG] 1                               (raw: 0x31

# [DEBUG] 9                               (raw: 0x39

# [DEBUG] 1                               (raw: 0x31

# [DEBUG] 6                               (raw: 0x36

# [DEBUG] 9                               (raw: 0x39

# [DEBUG] 8                               (raw: 0x38

# [DEBUG] 6                               (raw: 0x36

# [DEBUG] 8                               (raw: 0x38

# [DEBUG] 8                               (raw: 0x38

# [DEBUG] 1                               (raw: 0x31

# [DEBUG] 1                               (raw: 0x31

# [DEBUG] 7                               (raw: 0x37

# [DEBUG] 1                               (raw: 0x31

# [DEBUG] 6                               (raw: 0x36

# [DEBUG] 5                               (raw: 0x35

# [DEBUG] 3                               (raw: 0x33

# [DEBUG] 7                               (raw: 0x37

# [DEBUG] 5                               (raw: 0x35

# [DEBUG] 8                               (raw: 0x38

# [DEBUG] 1                               (raw: 0x31

# [DEBUG] 6                               (raw: 0x36

# [DEBUG] 5                               (raw: 0x35

# [DEBUG] 3                               (raw: 0x33

# [DEBUG] 8                               (raw: 0x38

# [DEBUG] 3                               (raw: 0x33

# [DEBUG] 7                               (raw: 0x37

# [DEBUG] 7                               (raw: 0x37

# [DEBUG] 0                               (raw: 0x30

# [DEBUG] 3                               (raw: 0x33

# [DEBUG] 8                               (raw: 0x38

# [DEBUG] "},                             (raw: 0x227d2c

# [DEBUG] {"trait_type":"Cell Count",     (raw: 0x7b2274726169745f74797065223a2243656c6c20436f756e74222c

# [DEBUG] "value":"                       (raw: 0x2276616c7565223a22

# [DEBUG] 7                               (raw: 0x37

# [DEBUG] "},                             (raw: 0x227d2c

# [DEBUG] {"trait_type":"Game Mode",      (raw: 0x7b2274726169745f74797065223a2247616d65204d6f6465222c

# [DEBUG] "value":"Infinite"}]            (raw: 0x2276616c7565223a22496e66696e697465227d5d

# [DEBUG] }                               (raw: 0x7d"""

example_text = """
[DEBUG] data:application/json,{         (raw: 0x646174613a6170706c69636174696f6e2f6a736f6e2c7b

[DEBUG] "name":"GoL2%20%23              (raw: 0x226e616d65223a22476f4c32253230253233

[DEBUG] 12345678912345678999            (raw: 0x3132333435363738393132333435363738393939

[DEBUG] ","description":"Snapshot       (raw: 0x222c226465736372697074696f6e223a22536e617073686f74

[DEBUG] %20of%20GoL2%20Game             (raw: 0x2532306f66253230476f4c3225323047616d65

[DEBUG] %20at%20generation%20           (raw: 0x253230617425323067656e65726174696f6e253230

[DEBUG] 12345678912345678999            (raw: 0x3132333435363738393132333435363738393939

[DEBUG] ","image":"                     (raw: 0x222c22696d616765223a22

[DEBUG] data:image/svg+xml,             (raw: 0x646174613a696d6167652f7376672b786d6c2c

[DEBUG] %253Csvg%2520xmlns=%2522        (raw: 0x25323533437376672532353230786d6c6e733d2532353232

[DEBUG] http://www.w3.org/2000/svg%2522 (raw: 0x687474703a2f2f7777772e77332e6f72672f323030302f7376672532353232

[DEBUG] %2520width=%2522910%2522        (raw: 0x253235323077696474683d25323532323931302532353232

[DEBUG] %2520height=%2522910%2522       (raw: 0x25323532306865696768743d25323532323931302532353232

[DEBUG] %2520viewBox=%25220%25200       (raw: 0x253235323076696577426f783d253235323230253235323030

[DEBUG] %2520910%2520910%2522%253E      (raw: 0x2532353230393130253235323039313025323532322532353345

[DEBUG] %253Cg%2520transform=           (raw: 0x25323533436725323532307472616e73666f726d3d

[DEBUG] %2522translate(5%25205)         (raw: 0x25323532327472616e736c617465283525323532303529

[DEBUG] %2522%253E                      (raw: 0x25323532322532353345

[DEBUG] %253Crect%2520width=            (raw: 0x253235334372656374253235323077696474683d

[DEBUG] %2522900%2522                   (raw: 0x25323532323930302532353232

[DEBUG] %2520height=%2522900%2522       (raw: 0x25323532306865696768743d25323532323930302532353232

[DEBUG] %2520fill=%2522%25231e222b      (raw: 0x253235323066696c6c3d25323532322532353233316532323262

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cg%2520stroke=%2522         (raw: 0x25323533436725323532307374726f6b653d2532353232

[DEBUG] %25235e6266%2522                (raw: 0x25323532333565363236362532353232

[DEBUG] %2520stroke-width=%25221%2522   (raw: 0x25323532307374726f6b652d77696474683d2532353232312532353232

[DEBUG] %253E                           (raw: 0x2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 120                             (raw: 0x313230

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 120                             (raw: 0x313230

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 120                             (raw: 0x313230

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 120                             (raw: 0x313230

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 180                             (raw: 0x313830

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 180                             (raw: 0x313830

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 180                             (raw: 0x313830

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 180                             (raw: 0x313830

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 240                             (raw: 0x323430

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 240                             (raw: 0x323430

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 240                             (raw: 0x323430

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 240                             (raw: 0x323430

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 300                             (raw: 0x333030

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 300                             (raw: 0x333030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 300                             (raw: 0x333030

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 300                             (raw: 0x333030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 420                             (raw: 0x343230

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 420                             (raw: 0x343230

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 420                             (raw: 0x343230

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 420                             (raw: 0x343230

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 480                             (raw: 0x343830

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 480                             (raw: 0x343830

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 480                             (raw: 0x343830

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 480                             (raw: 0x343830

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 540                             (raw: 0x353430

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 540                             (raw: 0x353430

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 540                             (raw: 0x353430

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 540                             (raw: 0x353430

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 600                             (raw: 0x363030

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 600                             (raw: 0x363030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 600                             (raw: 0x363030

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 600                             (raw: 0x363030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 660                             (raw: 0x363630

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 660                             (raw: 0x363630

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 660                             (raw: 0x363630

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 660                             (raw: 0x363630

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 720                             (raw: 0x373230

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 720                             (raw: 0x373230

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 720                             (raw: 0x373230

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 720                             (raw: 0x373230

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 780                             (raw: 0x373830

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 780                             (raw: 0x373830

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 780                             (raw: 0x373830

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 780                             (raw: 0x373830

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 840                             (raw: 0x383430

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 840                             (raw: 0x383430

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253Cline%2520x1=%2522          (raw: 0x25323533436c696e65253235323078313d2532353232

[DEBUG] 840                             (raw: 0x383430

[DEBUG] %2522%2520y1=%2522              (raw: 0x2532353232253235323079313d2532353232

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2522%2520x2=%2522              (raw: 0x2532353232253235323078323d2532353232

[DEBUG] 840                             (raw: 0x383430

[DEBUG] %2522%2520y2=%2522              (raw: 0x2532353232253235323079323d2532353232

[DEBUG] 900                             (raw: 0x393030

[DEBUG] %2522/%253E                     (raw: 0x25323532322f2532353345

[DEBUG] %253C/g%253E%253Cg%2520fill=    (raw: 0x25323533432f672532353345253235334367253235323066696c6c3d

[DEBUG] %2522%2523dff17b                (raw: 0x25323532322532353233646666313762

[DEBUG] %2522                           (raw: 0x2532353232

[DEBUG] %2520stroke=%2522%2523          (raw: 0x25323532307374726f6b653d25323532322532353233

[DEBUG] dff17b%2522                     (raw: 0x6466663137622532353232

[DEBUG] %2520stroke-width=%2522         (raw: 0x25323532307374726f6b652d77696474683d2532353232

[DEBUG] 0.5%2522%253E                   (raw: 0x302e3525323532322532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 0                               (raw: 0x30

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 120                             (raw: 0x313230

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 0                               (raw: 0x30

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 300                             (raw: 0x333030

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 0                               (raw: 0x30

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 0                               (raw: 0x30

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 600                             (raw: 0x363030

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 0                               (raw: 0x30

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 720                             (raw: 0x373230

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 0                               (raw: 0x30

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 780                             (raw: 0x373830

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 0                               (raw: 0x30

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 840                             (raw: 0x383430

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 0                               (raw: 0x30

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 60                              (raw: 0x3630

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 60                              (raw: 0x3630

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 420                             (raw: 0x343230

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 60                              (raw: 0x3630

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 660                             (raw: 0x363630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 60                              (raw: 0x3630

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 780                             (raw: 0x373830

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 60                              (raw: 0x3630

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 840                             (raw: 0x383430

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 60                              (raw: 0x3630

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 120                             (raw: 0x313230

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 120                             (raw: 0x313230

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 120                             (raw: 0x313230

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 180                             (raw: 0x313830

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 120                             (raw: 0x313230

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 120                             (raw: 0x313230

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 420                             (raw: 0x343230

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 120                             (raw: 0x313230

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 480                             (raw: 0x343830

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 120                             (raw: 0x313230

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 600                             (raw: 0x363030

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 120                             (raw: 0x313230

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 720                             (raw: 0x373230

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 120                             (raw: 0x313230

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 0                               (raw: 0x30

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 180                             (raw: 0x313830

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 180                             (raw: 0x313830

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 180                             (raw: 0x313830

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 180                             (raw: 0x313830

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 300                             (raw: 0x333030

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 180                             (raw: 0x313830

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 180                             (raw: 0x313830

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 480                             (raw: 0x343830

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 180                             (raw: 0x313830

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 540                             (raw: 0x353430

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 180                             (raw: 0x313830

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 660                             (raw: 0x363630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 180                             (raw: 0x313830

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 240                             (raw: 0x323430

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 120                             (raw: 0x313230

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 240                             (raw: 0x323430

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 240                             (raw: 0x323430

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 240                             (raw: 0x323430

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 300                             (raw: 0x333030

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 240                             (raw: 0x323430

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 360                             (raw: 0x333630

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 240                             (raw: 0x323430

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 540                             (raw: 0x353430

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 240                             (raw: 0x323430

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253Crect%2520                  (raw: 0x2532353343726563742532353230

[DEBUG] width=%2522                     (raw: 0x77696474683d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520height=%2522          (raw: 0x253235323225323532306865696768743d2532353232

[DEBUG] 60                              (raw: 0x3630

[DEBUG] %2522%2520transform=%2522       (raw: 0x253235323225323532307472616e73666f726d3d2532353232

[DEBUG] translate(                      (raw: 0x7472616e736c61746528

[DEBUG] 600                             (raw: 0x363030

[DEBUG] %2520                           (raw: 0x2532353230

[DEBUG] 240                             (raw: 0x323430

[DEBUG] )%2522/%253E                    (raw: 0x2925323532322f2532353345

[DEBUG] %253C/g%253E%253Crect%2520      (raw: 0x25323533432f6725323533452532353343726563742532353230

[DEBUG] width=%2522900%2522             (raw: 0x77696474683d25323532323930302532353232

[DEBUG] %2520height=%2522900%2522       (raw: 0x25323532306865696768743d25323532323930302532353232

[DEBUG] %2520fill=%2522none%2522        (raw: 0x253235323066696c6c3d25323532326e6f6e652532353232

[DEBUG] %2520stroke=%2522%2523          (raw: 0x25323532307374726f6b653d25323532322532353233

[DEBUG] 0a0c10%2522                     (raw: 0x3061306331302532353232

[DEBUG] %2520stroke-width=%2522         (raw: 0x25323532307374726f6b652d77696474683d2532353232

[DEBUG] 5%2522/%253E                    (raw: 0x3525323532322f2532353345

[DEBUG] %253C/g%253E%253C/svg%253E      (raw: 0x25323533432f67253235334525323533432f7376672532353345

[DEBUG] ","external_url":               (raw: 0x222c2265787465726e616c5f75726c223a

[DEBUG] "https://gol2.io",              (raw: 0x2268747470733a2f2f676f6c322e696f222c

[DEBUG] "attributes":                   (raw: 0x2261747472696275746573223a

[DEBUG] [                               (raw: 0x5b

[DEBUG] {"trait_type":"Generation",     (raw: 0x7b2274726169745f74797065223a2247656e65726174696f6e222c

[DEBUG] "value":"                       (raw: 0x2276616c7565223a22

[DEBUG] 12345678912345678999            (raw: 0x3132333435363738393132333435363738393939

[DEBUG] "},                             (raw: 0x227d2c

[DEBUG] {"trait_type":"Cell%20Count",   (raw: 0x7b2274726169745f74797065223a2243656c6c253230436f756e74222c

[DEBUG] "value":"                       (raw: 0x2276616c7565223a22

[DEBUG] 37                              (raw: 0x3337

[DEBUG] "},                             (raw: 0x227d2c

[DEBUG] {"trait_type":"Game%20Mode",    (raw: 0x7b2274726169745f74797065223a2247616d652532304d6f6465222c

[DEBUG] "value":"Infinite"}]            (raw: 0x2276616c7565223a22496e66696e697465227d5d

[DEBUG] }                               (raw: 0x7d
"""


result = extract_and_concatenate_debug_output(example_text)

def hex_to_ascii(hex_string):
    # Remove the '0x' prefix if present and strip any whitespace or newlines
    lines = hex_string.split("\n\n")
    hexes = []
    sss = ''
    i = 0
    for line in lines:
        spl = line.split('raw: ')[-1]
        if spl.startswith('0x'):
            hexes.append(spl)

    for hex in hexes:
        # print(hex)
        asc = bytes.fromhex(hex[2:]).decode('ascii')
        sss +=asc   


    print(sss)

        # hs = line.split( );
        # print(hs)
        # if line.startswith("0x"):
        #     hexes.append(line.split(' ')[-1])
        # print(line)
    # print('hi')


    # for hex in hexes:
    #     hex.strip()
        # print(bytes.fromhex(hex).decode('ascii'))
        # s = int(hex.strip(), 16)
        # print(s)
        # print("xxx", {hex})
    
    # Ensure the string contains only hexadecimal characters
    # hex_string = ''.join(char for char in hex_string if char in '0123456789abcdefABCDEF')

    # Convert hex string to bytes
    # hex_bytes = bytes.fromhex(hex_string)

    # Attempt to decode bytes to ASCII
    # try:
    #     ascii_string = hex_bytes.decode('ascii', errors='replace')
    # except UnicodeDecodeError:
    #     ascii_string = "<cannot decode>"

    # return ascii_string

# Example usage
print(hex_to_ascii(example_text))

# result = "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI5MTAiIGhlaWdodD0iOTEwIiB2aWV3Qm94PSIwIDAgOTEwIDkxMCI-PGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNSA1KSI-PHJlY3Qgd2lkdGg9IjkwMCIgaGVpZ2h0PSI5MDAiIGZpbGw9IiMxZTIyMmIiLz48ZyBzdHJva2U9IiM1ZTYyNjYiIHN0cm9rZS13aWR0aD0iMSI-PGxpbmUgeDE9IjAiIHkxPSI2MCIgeDI9IjkwMCIgeTI9IjYwIi8-PGxpbmUgeDE9IjYwIiB5MT0iMCIgeDI9IjYwIiB5Mj0iOTAwIi8-PGxpbmUgeDE9IjAiIHkxPSIxMjAiIHgyPSI5MDAiIHkyPSIxMjAiLz48bGluZSB4MT0iMTIwIiB5MT0iMCIgeDI9IjEyMCIgeTI9IjkwMCIvPjxsaW5lIHgxPSIwIiB5MT0iMTgwIiB4Mj0iOTAwIiB5Mj0iMTgwIi8-PGxpbmUgeDE9IjE4MCIgeTE9IjAiIHgyPSIxODAiIHkyPSI5MDAiLz48bGluZSB4MT0iMCIgeTE9IjI0MCIgeDI9IjkwMCIgeTI9IjI0MCIvPjxsaW5lIHgxPSIyNDAiIHkxPSIwIiB4Mj0iMjQwIiB5Mj0iOTAwIi8-PGxpbmUgeDE9IjAiIHkxPSIzMDAiIHgyPSI5MDAiIHkyPSIzMDAiLz48bGluZSB4MT0iMzAwIiB5MT0iMCIgeDI9IjMwMCIgeTI9IjkwMCIvPjxsaW5lIHgxPSIwIiB5MT0iMzYwIiB4Mj0iOTAwIiB5Mj0iMzYwIi8-PGxpbmUgeDE9IjM2MCIgeTE9IjAiIHgyPSIzNjAiIHkyPSI5MDAiLz48bGluZSB4MT0iMCIgeTE9IjQyMCIgeDI9IjkwMCIgeTI9IjQyMCIvPjxsaW5lIHgxPSI0MjAiIHkxPSIwIiB4Mj0iNDIwIiB5Mj0iOTAwIi8-PGxpbmUgeDE9IjAiIHkxPSI0ODAiIHgyPSI5MDAiIHkyPSI0ODAiLz48bGluZSB4MT0iNDgwIiB5MT0iMCIgeDI9IjQ4MCIgeTI9IjkwMCIvPjxsaW5lIHgxPSIwIiB5MT0iNTQwIiB4Mj0iOTAwIiB5Mj0iNTQwIi8-PGxpbmUgeDE9IjU0MCIgeTE9IjAiIHgyPSI1NDAiIHkyPSI5MDAiLz48bGluZSB4MT0iMCIgeTE9IjYwMCIgeDI9IjkwMCIgeTI9IjYwMCIvPjxsaW5lIHgxPSI2MDAiIHkxPSIwIiB4Mj0iNjAwIiB5Mj0iOTAwIi8-PGxpbmUgeDE9IjAiIHkxPSI2NjAiIHgyPSI5MDAiIHkyPSI2NjAiLz48bGluZSB4MT0iNjYwIiB5MT0iMCIgeDI9IjY2MCIgeTI9IjkwMCIvPjxsaW5lIHgxPSIwIiB5MT0iNzIwIiB4Mj0iOTAwIiB5Mj0iNzIwIi8-PGxpbmUgeDE9IjcyMCIgeTE9IjAiIHgyPSI3MjAiIHkyPSI5MDAiLz48bGluZSB4MT0iMCIgeTE9Ijc4MCIgeDI9IjkwMCIgeTI9Ijc4MCIvPjxsaW5lIHgxPSI3ODAiIHkxPSIwIiB4Mj0iNzgwIiB5Mj0iOTAwIi8-PGxpbmUgeDE9IjAiIHkxPSI4NDAiIHgyPSI5MDAiIHkyPSI4NDAiLz48bGluZSB4MT0iODQwIiB5MT0iMCIgeDI9Ijg0MCIgeTI9IjkwMCIvPjwvZz48ZyBmaWxsPSIjZGZmMTdiIiBzdHJva2U9IiNkZmYxN2IiIHN0cm9rZS13aWR0aD0iMC41Ij48cmVjdCB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDU0MCAzNjApIi8-PHJlY3Qgd2lkdGg9IjYwIiBoZWlnaHQ9IjYwIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSg2NjAgNDIwKSIvPjxyZWN0IHdpZHRoPSI2MCIgaGVpZ2h0PSI2MCIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNDgwIDQ4MCkiLz48cmVjdCB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDU0MCA0ODApIi8-PHJlY3Qgd2lkdGg9IjYwIiBoZWlnaHQ9IjYwIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSg3MjAgNDgwKSIvPjxyZWN0IHdpZHRoPSI2MCIgaGVpZ2h0PSI2MCIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNzgwIDQ4MCkiLz48cmVjdCB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDg0MCA0ODApIi8-PC9nPjxyZWN0IHdpZHRoPSI5MDAiIGhlaWdodD0iOTAwIiBmaWxsPSJub25lIiBzdHJva2U9IiMwYTBjMTAiIHN0cm9rZS13aWR0aD0iNSIvPjwvZz48L3N2Zz4="


# chunks = [result[i:i+8] for i in range(0, len(result), 8)]

# print(result)
# for chunk in chunks:
    # print(chunk)
    # print('|' + decode_base64(chunk) + '|\n|')
    # print('chunk: ' + chunk + '\ndecoded: |' + decoded + '|\n')

# decoded = decode_base64(result)

# x = hex_to_ascii(example_text)
# print(x)



