//
// Copyright 2024 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

use std::time::SystemTime;

use const_str::hex;
use libsignal_bridge_macros::*;
use libsignal_core::Aci;
use libsignal_keytrans::{
    Signature, StoredAccountData, StoredMonitoringData, StoredTreeHead, TreeHead,
};
use libsignal_net::keytrans::SearchResult;
use libsignal_protocol::IdentityKey;
use uuid::Uuid;

use crate::*;

#[cfg(feature = "jni")]
const TEST_ACI: Uuid = uuid::uuid!("90c979fd-eab4-4a08-b6da-69dedeab9b29");
#[cfg(feature = "jni")]
const TEST_ACI_IDENTITY_KEY_BYTES: &[u8] =
    &hex!("05111f9464c1822c6a2405acf1c5a4366679dc3349fc8eb015c8d7260e3f771177");

#[bridge_fn(node = false, ffi = false)]
fn TESTING_ChatSearchResult() -> SearchResult {
    let aci = Aci::from(TEST_ACI);
    let last_tree_head = Some(StoredTreeHead {
        tree_head: Some(TreeHead {
            tree_size: 42,
            timestamp: 42424242,
            signatures: vec![Signature {
                auditor_public_key: vec![1, 2, 3],
                signature: vec![4, 5, 6],
            }],
        }),
        root: vec![42; 32],
    });
    fn make_monitoring_data(byte: u8) -> StoredMonitoringData {
        StoredMonitoringData {
            index: std::iter::repeat(byte).take(32).collect(),
            pos: byte.into(),
            ptrs: Default::default(),
            owned: false,
        }
    }
    SearchResult {
        aci_identity_key: IdentityKey::decode(TEST_ACI_IDENTITY_KEY_BYTES)
            .expect("valid serialized key"),
        aci_for_e164: Some(aci),
        aci_for_username_hash: Some(aci),
        timestamp: SystemTime::UNIX_EPOCH,
        account_data: StoredAccountData {
            aci: Some(make_monitoring_data(0)),
            e164: Some(make_monitoring_data(1)),
            username_hash: Some(make_monitoring_data(2)),
            last_tree_head,
        },
    }
}
