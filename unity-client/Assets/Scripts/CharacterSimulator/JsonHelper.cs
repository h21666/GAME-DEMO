using System;
using UnityEngine;

namespace AIGCCharacterSimulator.Client
{
    public static class JsonHelper
    {
        [Serializable]
        private class Wrapper<T>
        {
            public T[] Items;
        }

        public static T[] FromJsonArray<T>(string json)
        {
            if (string.IsNullOrEmpty(json))
            {
                return new T[0];
            }

            Wrapper<T> wrapper = JsonUtility.FromJson<Wrapper<T>>("{\"Items\":" + json + "}");
            if (wrapper == null || wrapper.Items == null)
            {
                return new T[0];
            }

            return wrapper.Items;
        }
    }
}

