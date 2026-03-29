import os;
import json;
import from urllib.request { Request, urlopen }
import from urllib.error { HTTPError }

import from db { get_companies_full }
import from matching { normalize_company_query }

glob VISUAL_MODEL: str = "gpt-5.4-nano";

def _company_name_list(event_id: str) -> list {
    companies = get_companies_full(event_id);
    names: list = [];

    for company in companies {
        if "name" in company {
            names.append(company["name"]);
        }
    }

    return names;
}

def extract_response_text(parsed: dict) -> str {
    if "output_text" in parsed {
        top_text: str = str(parsed["output_text"]).strip();
        if top_text != "" {
            return top_text;
        }
    }

    if "output" not in parsed {
        return "";
    }

    outputs = parsed["output"];

    for item in outputs {
        if "content" not in item {
            continue;
        }

        contents = item["content"];
        for block in contents {
            if "text" in block {
                text_value: str = str(block["text"]).strip();
                if text_value != "" {
                    return text_value;
                }
            }
        }
    }

    return "";
}


def identify_company_name_from_image(
    image_data: str, image_mime_type: str, event_id: str
) -> dict {
    api_key = os.getenv("OPENAI_API_KEY");
    if api_key is None or api_key == "" {
        return {"error": "missing_openai_api_key"};
    }

    if image_data.strip() == "" {
        return {"error": "missing_image"};
    }

    company_names = _company_name_list(event_id);

    if len(company_names) == 0 {
        return {"error": "empty_company_list"};
    }

    allowed_lines: list[str] = [];
    for name in company_names {
        allowed_lines.append("- " + str(name));
    }
    allowed_names_text: str = "\n".join(allowed_lines);

    prompt: str = (
        "You are identifying a company from a photographed company logo at a career fair.\n"
        "The correct answer MUST be one of the allowed company names below, or NOT_FOUND.\n"
        "Ignore case differences. Do not explain.\n"
        "Return JSON only in exactly this shape:\n"
        "{\"company_name\": \"Exact Company Name From List\"}\n"
        "or\n"
        "{\"company_name\": \"NOT_FOUND\"}\n\n"
        "Allowed company names:\n" + allowed_names_text
    );

    mime_type: str = image_mime_type.strip()
        if image_mime_type.strip() != ""
        else "image/jpeg";
    image_url: str = "data:" + mime_type + ";base64," + image_data;

    payload: dict = {
        "model": VISUAL_MODEL,
        "input": [
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": prompt},
                    {"type": "input_image", "image_url": image_url}
                ]
            }
        ],
        "text": {
            "format": {
                "type": "json_schema",
                "name": "company_identifier",
                "schema": {
                    "type": "object",
                    "properties": {"company_name": {"type": "string"}},
                    "required": ["company_name"],
                    "additionalProperties": False
                }
            }
        }
    };

    body: bytes = json.dumps(payload).encode("utf-8");

    req = Request(
        "https://api.openai.com/v1/responses",
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer " + api_key
        },
        method="POST"
    );

    try {
        resp = urlopen(req);
        raw: str = resp.read().decode("utf-8");
        parsed = json.loads(raw);

        output_text: str = extract_response_text(parsed);

        if output_text == "" {
            return {"error": "empty_visual_output", "details": raw};
        }

        result = json.loads(output_text);

        if "company_name" not in result {
            return {"error": "invalid_visual_output"};
        }

        company_name: str = str(result["company_name"]).strip();
        if company_name == "" or company_name == "NOT_FOUND" {
            return {"error": "company_not_found"};
        }

        normalized_target: str = normalize_company_query(company_name);

        for allowed in company_names {
            allowed_name: str = str(allowed);
            if normalize_company_query(allowed_name) == normalized_target {
                return {"company_name": allowed_name};
            }
        }

        return {"error": "company_not_found"};
    } except HTTPError as e {
        return {
            "error": "visual_api_http_error",
            "details": "HTTP request to OpenAI failed"
        };
    } except Exception as e {
        return {"error": "visual_api_failed", "details": str(e)};
    }
}
