# Blood compatibility map:
# Key   = recipient blood group (what the request needs)
# Value = list of donor blood groups that can donate to this recipient
COMPATIBILITY_MAP: dict[str, list[str]] = {
    "A+":  ["A+", "A-", "O+", "O-"],
    "A-":  ["A-", "O-"],
    "B+":  ["B+", "B-", "O+", "O-"],
    "B-":  ["B-", "O-"],
    "AB+": ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],  # universal recipient
    "AB-": ["AB-", "A-", "B-", "O-"],
    "O+":  ["O+", "O-"],
    "O-":  ["O-"],  # universal donor — can only receive O-
}


def get_compatible_donor_groups(recipient_blood_group: str) -> list[str]:
    """
    Given a recipient's blood group, returns all donor blood groups
    that are compatible for donation.

    Example:
        get_compatible_donor_groups("A+") → ["A+", "A-", "O+", "O-"]
    """
    return COMPATIBILITY_MAP.get(recipient_blood_group, [])


def can_donate(donor_blood_group: str, recipient_blood_group: str) -> bool:
    """
    Returns True if a donor with donor_blood_group can donate
    to a recipient needing recipient_blood_group.
    """
    compatible = get_compatible_donor_groups(recipient_blood_group)
    return donor_blood_group in compatible